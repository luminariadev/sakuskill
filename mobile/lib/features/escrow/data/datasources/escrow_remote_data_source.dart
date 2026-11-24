import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../models/escrow_order_model.dart';

typedef JsonMap = Map<String, dynamic>;
typedef HeaderMap = Map<String, String>;

class EscrowException implements Exception {
  const EscrowException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() =>
      code != null ? 'EscrowException [$code]: $message' : 'EscrowException: $message';
}

/// Sumber data REST untuk modul Order Lifecycle & Escrow (`/api/v1/orders`).
class EscrowRemoteDataSource {
  EscrowRemoteDataSource({
    http.Client? client,
    String? baseUrl,
    this.tokenProvider,
    this.onUnauthorized,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function()? tokenProvider;
  final void Function()? onUnauthorized;

  Future<HeaderMap> _headers() async {
    final token = await tokenProvider?.call();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  JsonMap _parseResponse(http.Response response, Uri uri) {
    final dynamic body = response.bodyBytes.isEmpty
        ? null
        : jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        onUnauthorized?.call();
      }
      String? serverMsg;
      String? errorCode;
      if (body is JsonMap) {
        serverMsg = body['message'] as String?;
        final errObj = body['error'];
        if (errObj is JsonMap) {
          errorCode = errObj['code'] as String?;
          serverMsg ??= errObj['message'] as String?;
        }
      }
      throw EscrowException(
        serverMsg ?? 'HTTP ${response.statusCode} dari $uri',
        code: errorCode,
      );
    }

    if (body is! JsonMap || body['success'] != true) {
      throw EscrowException(
        (body is JsonMap ? body['message'] as String? : null) ??
            'Format respons tidak sesuai kontrak API',
      );
    }
    return body;
  }

  String _normalizeRoleParam(String peran) {
    switch (peran.toLowerCase().trim()) {
      case 'pembeli':
      case 'pelanggan':
      case 'customer':
        return 'pelanggan';
      case 'penjual':
      case 'penyedia':
      case 'provider':
        return 'penyedia';
      default:
        return peran;
    }
  }

  /// POST /api/v1/orders
  Future<EscrowOrderModel> createOrder({
    required String listingId,
    required String deskripsiKebutuhan,
    required int hargaDisepakati,
    required int durasiHari,
    String? catatanKlien,
  }) async {
    final uri = Uri.parse('$_baseUrl/orders');
    final combinedScope = (catatanKlien != null && catatanKlien.trim().isNotEmpty)
        ? '${deskripsiKebutuhan.trim()}\nCatatan: ${catatanKlien.trim()}'
        : deskripsiKebutuhan.trim();

    final safeScope = combinedScope.length >= 10
        ? combinedScope
        : '$combinedScope (Kebutuhan layanan)';

    final deadline =
        DateTime.now().toUtc().add(Duration(days: durasiHari < 1 ? 1 : durasiHari));

    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            'listing_id': listingId,
            'ruang_lingkup': safeScope,
            'catatan_kebutuhan': safeScope,
            'harga_kesepakatan': hargaDisepakati,
            'tenggat_pekerjaan': deadline.toIso8601String(),
          }),
        )
        .timeout(AppConfig.networkTimeout);

    final body = _parseResponse(response, uri);
    return EscrowOrderModel.fromJson(body['data'] as JsonMap);
  }

  /// GET /api/v1/orders?role=pelanggan|penyedia&status=...
  Future<List<EscrowOrderModel>> fetchMyOrders({
    String peran = 'pelanggan',
    String? status,
  }) async {
    final normalizedRole = _normalizeRoleParam(peran);
    final uri = Uri.parse('$_baseUrl/orders').replace(
      queryParameters: {
        if (normalizedRole.isNotEmpty) 'role': normalizedRole,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    final response = await _client
        .get(uri, headers: await _headers())
        .timeout(AppConfig.networkTimeout);

    final body = _parseResponse(response, uri);
    final items = body['data'];
    if (items is! List) return const [];

    return items
        .whereType<JsonMap>()
        .map(EscrowOrderModel.fromJson)
        .toList(growable: false);
  }

  /// GET /api/v1/orders/:id
  Future<EscrowOrderModel> fetchOrderDetail(String orderId) async {
    final uri = Uri.parse('$_baseUrl/orders/$orderId');
    final response = await _client
        .get(uri, headers: await _headers())
        .timeout(AppConfig.networkTimeout);

    final body = _parseResponse(response, uri);
    return EscrowOrderModel.fromJson(body['data'] as JsonMap);
  }

  /// POST /api/v1/orders/:id/accept
  Future<EscrowOrderModel> acceptOrder(
    String orderId, {
    String? ruangLingkup,
    int? hargaKesepakatan,
    DateTime? tenggatPekerjaan,
  }) async {
    final uri = Uri.parse('$_baseUrl/orders/$orderId/accept');
    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            if (ruangLingkup != null && ruangLingkup.trim().length >= 10)
              'ruang_lingkup': ruangLingkup.trim(),
            if (hargaKesepakatan != null) 'harga_kesepakatan': hargaKesepakatan,
            if (tenggatPekerjaan != null)
              'tenggat_pekerjaan': tenggatPekerjaan.toUtc().toIso8601String(),
          }),
        )
        .timeout(AppConfig.networkTimeout);

    final body = _parseResponse(response, uri);
    return EscrowOrderModel.fromJson(body['data'] as JsonMap);
  }

  /// POST /api/v1/orders/:id/reject
  Future<EscrowOrderModel> rejectOrder(String orderId, {String? alasan}) async {
    final uri = Uri.parse('$_baseUrl/orders/$orderId/reject');
    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            if (alasan != null && alasan.trim().length >= 3)
              'alasan': alasan.trim(),
          }),
        )
        .timeout(AppConfig.networkTimeout);

    final body = _parseResponse(response, uri);
    return EscrowOrderModel.fromJson(body['data'] as JsonMap);
  }

  /// POST /api/v1/orders/:id/start
  Future<EscrowOrderModel> startWorkOrder(String orderId) async {
    final uri = Uri.parse('$_baseUrl/orders/$orderId/start');
    final response = await _client
        .post(uri, headers: await _headers())
        .timeout(AppConfig.networkTimeout);

    final body = _parseResponse(response, uri);
    return EscrowOrderModel.fromJson(body['data'] as JsonMap);
  }

  /// POST /api/v1/orders/:id/proposals (Negosiasi scope, harga, atau tenggat)
  Future<EscrowOrderModel> submitProposal({
    required String orderId,
    required String deskripsiRuangLingkup,
    required int hargaTawaran,
    DateTime? tenggatUsulan,
  }) async {
    final uri = Uri.parse('$_baseUrl/orders/$orderId/proposals');
    final safeScope = deskripsiRuangLingkup.trim().length >= 10
        ? deskripsiRuangLingkup.trim()
        : '${deskripsiRuangLingkup.trim()} (Penyesuaian ruang lingkup)';

    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            'deskripsi_ruang_lingkup': safeScope,
            'harga_tawaran': hargaTawaran,
            if (tenggatUsulan != null)
              'tenggat_usulan': tenggatUsulan.toUtc().toIso8601String(),
          }),
        )
        .timeout(AppConfig.networkTimeout);

    final body = _parseResponse(response, uri);
    return EscrowOrderModel.fromJson(body['data'] as JsonMap);
  }

  /// Penyedia mengajukan klaim selesai (`POST /orders/:id/request-completion`).
  Future<void> deliverWork({
    required String orderId,
    required String tautanBerkas,
    required String catatanPenyedia,
    String? mockupUrl,
    bool konfirmasiKesesuaianBrief = true,
  }) async {
    final current = await fetchOrderDetail(orderId);
    if (current.statusKode == 'accepted') {
      await startWorkOrder(orderId);
    }

    final uri = Uri.parse('$_baseUrl/orders/$orderId/request-completion');
    final response = await _client
        .post(uri, headers: await _headers())
        .timeout(AppConfig.networkTimeout);

    _parseResponse(response, uri);
  }

  /// Pelanggan mengonfirmasi selesai (`POST /orders/:id/complete`)
  Future<void> releaseFund(
    String orderId, {
    int? rating,
    String? komentar,
  }) async {
    final completeUri = Uri.parse('$_baseUrl/orders/$orderId/complete');
    final completeResponse = await _client
        .post(completeUri, headers: await _headers())
        .timeout(AppConfig.networkTimeout);

    _parseResponse(completeResponse, completeUri);

    if (rating != null && rating >= 1 && rating <= 5) {
      await submitReview(
        orderId: orderId,
        rating: rating,
        komentar: komentar,
      );
    }
  }

  /// POST /api/v1/orders/:id/reviews
  Future<void> submitReview({
    required String orderId,
    required int rating,
    int? ratingKualitas,
    int? ratingKetepatanWaktu,
    String? komentar,
  }) async {
    final uri = Uri.parse('$_baseUrl/orders/$orderId/reviews');
    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            'rating': rating,
            if (ratingKualitas != null) 'rating_kualitas': ratingKualitas,
            if (ratingKetepatanWaktu != null)
              'rating_ketepatan_waktu': ratingKetepatanWaktu,
            if (komentar != null && komentar.trim().length >= 3)
              'komentar': komentar.trim(),
          }),
        )
        .timeout(AppConfig.networkTimeout);

    _parseResponse(response, uri);
  }

  /// Pelanggan mengajukan revisi / negosiasi ulang (`POST /orders/:id/proposals`).
  Future<void> requestRevision({
    required String orderId,
    required String catatanRevisi,
  }) async {
    final current = await fetchOrderDetail(orderId);
    await submitProposal(
      orderId: orderId,
      deskripsiRuangLingkup: catatanRevisi,
      hargaTawaran: current.harga,
      tenggatUsulan: current.tenggat,
    );
  }

  /// Pengajuan perpanjangan tenggat (`POST /orders/:id/time-extensions`).
  Future<EscrowOrderModel> requestTimeExtension({
    required String orderId,
    required int tambahanJam,
    required String alasan,
    int progresPersen = 75,
  }) async {
    final uri = Uri.parse('$_baseUrl/orders/$orderId/time-extensions');
    final safeReason = alasan.trim().length >= 5
        ? '${alasan.trim()} (Progres: $progresPersen%)'
        : '${alasan.trim()} - Permintaan tambahan waktu $tambahanJam jam (Progres: $progresPersen%)';

    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            'tambahan_jam': tambahanJam,
            'alasan': safeReason,
          }),
        )
        .timeout(AppConfig.networkTimeout);

    final body = _parseResponse(response, uri);
    return EscrowOrderModel.fromJson(body['data'] as JsonMap);
  }

  /// Keputusan persetujuan perpanjangan waktu (`POST /orders/:id/time-extensions/decide`).
  Future<EscrowOrderModel> decideTimeExtension({
    required String orderId,
    required bool disetujui,
  }) async {
    final uri = Uri.parse('$_baseUrl/orders/$orderId/time-extensions/decide');
    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({'disetujui': disetujui}),
        )
        .timeout(AppConfig.networkTimeout);

    final body = _parseResponse(response, uri);
    return EscrowOrderModel.fromJson(body['data'] as JsonMap);
  }

  /// Pembatalan order (`POST /orders/:id/cancel`).
  Future<void> cancelOverdueOrder(
    String orderId, {
    String alasan = 'Pesanan dibatalkan karena melewati tenggat pengerjaan.',
  }) async {
    final uri = Uri.parse('$_baseUrl/orders/$orderId/cancel');
    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({'alasan': alasan}),
        )
        .timeout(AppConfig.networkTimeout);

    _parseResponse(response, uri);
  }

  /// Ajukan banding / komplain sebagai proposal penyelesaian (`POST /orders/:id/proposals`).
  Future<void> submitAppeal({
    required String orderId,
    required String alasan,
    required int progresPersen,
    String? tautanBukti,
  }) async {
    final current = await fetchOrderDetail(orderId);
    final note =
        'Banding ($progresPersen%): $alasan${tautanBukti != null && tautanBukti.isNotEmpty ? ' | Bukti: $tautanBukti' : ''}';
    await submitProposal(
      orderId: orderId,
      deskripsiRuangLingkup: note,
      hargaTawaran: current.harga,
      tenggatUsulan: current.tenggat,
    );
  }

  /// --- MODUL SIMULASI PEMBAYARAN MVP (`/api/v1/payments`) ---[cite: 7, 11]

  /// POST /api/v1/payments (Pelanggan membuat sesi pembayaran)[cite: 7, 11]
  Future<JsonMap> createPayment(String orderId) async {
    final uri = Uri.parse('$_baseUrl/payments');
    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            'order_id': orderId,
            'metode_simulasi': 'SIMULASI_MVP',
          }),
        )
        .timeout(AppConfig.networkTimeout);
    return _parseResponse(response, uri)['data'] as JsonMap;
  }

  /// POST /api/v1/payments/:orderId/simulate-success (Hanya dev/demo/test)[cite: 7, 11]
  Future<JsonMap> simulatePaymentSuccess(String orderId) async {
    final uri = Uri.parse('$_baseUrl/payments/$orderId/simulate-success');
    final response = await _client
        .post(uri, headers: await _headers(), body: jsonEncode({}))
        .timeout(AppConfig.networkTimeout);
    return _parseResponse(response, uri)['data'] as JsonMap;
  }

  /// POST /api/v1/payments/:orderId/simulate-failed[cite: 7, 11]
  Future<JsonMap> simulatePaymentFailed(String orderId, {String? alasan}) async {
    final uri = Uri.parse('$_baseUrl/payments/$orderId/simulate-failed');
    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            if (alasan != null && alasan.trim().isNotEmpty) 'alasan_gagal': alasan.trim(),
          }),
        )
        .timeout(AppConfig.networkTimeout);
    return _parseResponse(response, uri)['data'] as JsonMap;
  }

  /// GET /api/v1/payments/:orderId[cite: 7, 10]
  Future<JsonMap> fetchPayment(String orderId) async {
    final uri = Uri.parse('$_baseUrl/payments/$orderId');
    final response = await _client
        .get(uri, headers: await _headers())
        .timeout(AppConfig.networkTimeout);
    return _parseResponse(response, uri)['data'] as JsonMap;
  }

  /// GET /api/v1/orders/:id/messages
  Future<List<JsonMap>> fetchOrderMessages(String orderId) async {
    final uri = Uri.parse('$_baseUrl/orders/$orderId/messages');
    final response = await _client
        .get(uri, headers: await _headers())
        .timeout(AppConfig.networkTimeout);

    final body = _parseResponse(response, uri);
    final items = body['data'];
    if (items is! List) return const [];
    return items.whereType<JsonMap>().toList(growable: false);
  }

  /// POST /api/v1/orders/:id/messages
  Future<JsonMap> sendOrderMessage({
    required String orderId,
    required String isiPesan,
  }) async {
    final uri = Uri.parse('$_baseUrl/orders/$orderId/messages');
    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({'isi_pesan': isiPesan.trim()}),
        )
        .timeout(AppConfig.networkTimeout);

    final body = _parseResponse(response, uri);
    return body['data'] as JsonMap;
  }
}