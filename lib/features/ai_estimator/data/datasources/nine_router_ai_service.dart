import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/campus_constants.dart';
import '../../domain/usecases/calculate_ai_price.dart';

class NineRouterAIService {
  // Groq Cloud / 9router LLM Endpoint Configuration
  static const String _defaultBaseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _defaultModel = 'openai/gpt-oss-120b';

  static const String _envApiKey = String.fromEnvironment(
    'ROUTER_API_KEY',
    defaultValue: String.fromEnvironment('GROQ_API_KEY', defaultValue: ''),
  );

  /// Runtime API key override (configured via in-app settings dialog)
  static String? customApiKey;

  static String get apiKey {
    if (customApiKey != null && customApiKey!.trim().isNotEmpty) {
      return customApiKey!.trim();
    }
    return _envApiKey;
  }

  static const String modelName = String.fromEnvironment('ROUTER_MODEL', defaultValue: _defaultModel);

  /// Runtime endpoint override (e.g. when user sets custom Tunnel/LAN IP in the mobile UI)
  static String? customBaseUrl;

  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      return customBaseUrl!.trim();
    }
    const envUrl = String.fromEnvironment('ROUTER_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    return _defaultBaseUrl;
  }

  /// Request live price estimate from LLM service (Groq Cloud / 9router)
  static Future<AIPriceEstimateResult> estimatePrice({
    required ServiceCategory category,
    required ServiceComplexity complexity,
    required int deliveryHours,
    required OutputFormat outputFormat,
    String? customDescription,
  }) async {
    // If Groq Cloud is used but no API key is provided, safely use deterministic campus algorithm
    if (baseUrl.contains('groq.com') && apiKey.isEmpty) {
      final fallback = CalculateAIPriceUseCase.execute(
        category: category,
        complexity: complexity,
        deliveryHours: deliveryHours,
        outputFormat: outputFormat,
      );

      return AIPriceEstimateResult(
        minPrice: fallback.minPrice,
        recommendedPrice: fallback.recommendedPrice,
        maxPrice: fallback.maxPrice,
        calculationBreakdown: [
          ...fallback.calculationBreakdown,
          'Info: Disarankan menyetel API Key Groq di menu konfigurasi untuk analisis mendalam.',
        ],
        academicSafetyNotice: fallback.academicSafetyNotice,
        isRealTimeAI: false,
        aiModelUsed: 'Algoritma Kampus Standar (Offline Fallback)',
      );
    }
    final categoryLabel = CategoryMeta.info[category]?.label ?? 'Jasa Kampus';
    final complexityText = switch (complexity) {
      ServiceComplexity.simple => 'Sederhana (Tugas rutin ringan)',
      ServiceComplexity.medium => 'Sedang (Butuh keahlian teknis khusus)',
      ServiceComplexity.complex => 'Kompleks (Pengerjaan tingkat lanjut)',
    };
    final formatText = switch (outputFormat) {
      OutputFormat.digitalFile => 'Penyerahan File Digital (Google Drive / GitHub)',
      OutputFormat.onSitePresence => 'Tatap Muka Langsung di Kampus Cibiru Bandung',
      OutputFormat.onlineConsultation => 'Konsultasi / Mentoring Daring Google Meet',
    };

    final prompt = '''
Kamu adalah AI Price Estimator untuk marketplace mikro-servis mahasiswa kampus UIN Sunan Gunung Djati Bandung (SakuSkill).
Hitung estimasi harga pasar wajar mahasiswa untuk jasa berikut:
- Kategori: $categoryLabel
- Deskripsi / Keahlian: ${customDescription?.trim().isNotEmpty == true ? customDescription : categoryLabel}
- Kompleksitas: $complexityText
- Durasi Pengerjaan: $deliveryHours jam
- Metode Penyerahan: $formatText
- Target Konsumen: Mahasiswa UIN SGD Cibiru Bandung (daya beli mahasiswa)

KEMBALIKAN HANYA VALID RAW JSON MURNI TANPA MARKDOWN BACKTICKS:
{
  "recommendedPrice": 45000,
  "minPrice": 35000,
  "maxPrice": 55000,
  "breakdown": [
    "Poin analisis tarif 1",
    "Poin analisis tarif 2",
    "Poin analisis tarif 3"
  ],
  "academicSafetyNotice": "Pemberitahuan Integritas: Jasa teknikal/kreatif mahasiswa sah. Joki tugas kuliah dilarang keras."
}
''';

    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': modelName,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'Kamu adalah AI Price Estimator resmi kampus UIN SGD Bandung. Balas hanya JSON valid tanpa teks pengantar.',
                },
                {'role': 'user', 'content': prompt},
              ],
              'stream': false,
              'temperature': 0.1,
            }),
          )
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final content = decoded['choices']?[0]?['message']?['content'] as String? ?? '';

        // Extract JSON substring
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
        if (jsonMatch != null) {
          final parsed = jsonDecode(jsonMatch.group(0)!);
          final recPrice = (parsed['recommendedPrice'] as num?)?.toInt() ?? 45000;
          final minP = (parsed['minPrice'] as num?)?.toInt() ?? (recPrice * 0.8).round();
          final maxP = (parsed['maxPrice'] as num?)?.toInt() ?? (recPrice * 1.25).round();

          List<String> breakdown = [];
          if (parsed['breakdown'] is List) {
            breakdown = (parsed['breakdown'] as List).map((e) => e.toString()).toList();
          } else if (parsed['breakdown'] is Map) {
            final map = parsed['breakdown'] as Map;
            breakdown = map.entries.map((e) => '${e.key}: ${e.value}').toList();
          }
          if (breakdown.isEmpty) {
            breakdown = [
              'Analisis Pasar Mahasiswa UIN Cibiru',
              'Estimasi waktu pengerjaan: $deliveryHours jam',
              'Tarif direkomendasikan AI Groq Cloud',
            ];
          }

          final notice = parsed['academicSafetyNotice']?.toString() ??
              'Pemberitahuan Integritas: Tarif ini dianalisis oleh AI untuk jasa praktis mahasiswa. Joki tugas dilarang keras.';

          return AIPriceEstimateResult(
            minPrice: minP,
            recommendedPrice: recPrice,
            maxPrice: maxP,
            calculationBreakdown: breakdown,
            academicSafetyNotice: notice,
            isRealTimeAI: true,
            aiModelUsed: 'Groq Cloud LLM ($modelName)',
          );
        }
      }
    } catch (_) {
      // In case of timeout or offline, smoothly fall back to deterministic algorithm
    }

    // Deterministic Clean Fallback
    final fallback = CalculateAIPriceUseCase.execute(
      category: category,
      complexity: complexity,
      deliveryHours: deliveryHours,
      outputFormat: outputFormat,
    );

    return AIPriceEstimateResult(
      minPrice: fallback.minPrice,
      recommendedPrice: fallback.recommendedPrice,
      maxPrice: fallback.maxPrice,
      calculationBreakdown: [
        ...fallback.calculationBreakdown,
        'Catatan: Menggunakan Algoritma Cadangan (9router offline/timeout)',
      ],
      academicSafetyNotice: fallback.academicSafetyNotice,
      isRealTimeAI: false,
      aiModelUsed: 'Algoritma Kampus Standar (Offline Fallback)',
    );
  }
}
