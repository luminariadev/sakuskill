import 'dart:math' as math;
import '../../../../core/constants/campus_constants.dart';
import '../../../../core/utils/currency_formatter.dart';

enum ServiceComplexity {
  simple,
  medium,
  complex,
}

enum OutputFormat {
  digitalFile,
  onSitePresence,
  onlineConsultation,
}

class AIPriceEstimateResult {
  final int minPrice;
  final int recommendedPrice;
  final int maxPrice;
  final List<String> calculationBreakdown;
  final String academicSafetyNotice;
  final bool isRealTimeAI;
  final String aiModelUsed;

  const AIPriceEstimateResult({
    required this.minPrice,
    required this.recommendedPrice,
    required this.maxPrice,
    required this.calculationBreakdown,
    required this.academicSafetyNotice,
    this.isRealTimeAI = false,
    this.aiModelUsed = 'Algoritma Kampus Standar',
  });
}

class CalculateAIPriceUseCase {
  static AIPriceEstimateResult execute({
    required ServiceCategory category,
    required ServiceComplexity complexity,
    required int deliveryHours,
    required OutputFormat outputFormat,
  }) {
    final meta = CategoryMeta.info[category] ?? CategoryMeta.info[ServiceCategory.itSupport]!;
    final baseRate = meta.baseRate;

    final double compMult = switch (complexity) {
      ServiceComplexity.simple => 1.0,
      ServiceComplexity.medium => 1.35,
      ServiceComplexity.complex => 1.75,
    };

    final int formatAddon = switch (outputFormat) {
      OutputFormat.digitalFile => 0,
      OutputFormat.onSitePresence => 15000,
      OutputFormat.onlineConsultation => 5000,
    };

    final int clampedHours = deliveryHours.clamp(1, 48);
    final double timeWeight = 1.0 + (math.log(clampedHours) / math.ln10) * 0.35;

    final double rawPrice = (baseRate * compMult * timeWeight) + formatAddon;
    final int recommendedPrice = (rawPrice / 5000).round() * 5000;
    final int minPrice = math.max(20000, ((recommendedPrice * 0.85) / 5000).round() * 5000);
    final int maxPrice = ((recommendedPrice * 1.25) / 5000).round() * 5000;

    final breakdown = [
      'Tarif Dasar Kategori ${meta.label}: ${FormatterUtils.formatIDR(baseRate)}',
      'Tingkat Kompleksitas (${complexity.name}): Pengali x${compMult.toStringAsFixed(2)}',
      'Faktor Durasi ($clampedHours jam): x${timeWeight.toStringAsFixed(2)}',
      outputFormat == OutputFormat.onSitePresence
          ? 'Tatap Muka Cibiru: +Rp 15.000 (Akomodasi Lokal)'
          : 'Output: ${outputFormat == OutputFormat.digitalFile ? 'File Digital Drive' : 'Sesi Daring Meet'}',
      'Rekomendasi Wajar Mahasiswa: ${FormatterUtils.formatIDR(recommendedPrice)}',
    ];

    return AIPriceEstimateResult(
      minPrice: minPrice,
      recommendedPrice: recommendedPrice,
      maxPrice: maxPrice,
      calculationBreakdown: breakdown,
      academicSafetyNotice:
          'Pemberitahuan Integritas: Tarif ini HANYA berlaku untuk jasa keahlian teknis/kreatif praktis. SakuSkill menolak dan memblokir seluruh estimasi untuk perjokian tugas kuliah, makalah, maupun skripsi.',
    );
  }
}
