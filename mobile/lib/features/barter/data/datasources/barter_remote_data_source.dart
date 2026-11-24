import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../models/barter_model.dart';

typedef JsonMap = Map<String, dynamic>;
typedef HeaderMap = Map<String, String>;

class BarterException implements Exception {
  const BarterException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() =>
      code != null ? 'BarterException [$code]: $message' : 'BarterException: $message';
}

class BarterRemoteDataSource {
  BarterRemoteDataSource({
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
      throw BarterException(
        serverMsg ?? 'HTTP ${response.statusCode} dari $uri',
        code: errorCode,
      );
    }

    if (body is! JsonMap || body['success'] != true) {
      throw BarterException(
        (body is JsonMap ? body['message'] as String? : null) ??
            'Format respons tidak sesuai kontrak API',
      );
    }
    return body;
  }

  Future<BarterAgreementModel> createBarterOffer({
    required String listingId,
    String? listingPengajuId,
    required String deskripsiJasaPengaju,
    required String deskripsiJasaPenerima,
    required DateTime tenggatPekerjaan,
  }) async {
    final uri = Uri.parse('$_baseUrl/barter');
    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            'listing_id': listingId,
            if (listingPengajuId != null) 'listing_pengaju_id': listingPengajuId,
            'deskripsi_jasa_pengaju': deskripsiJasaPengaju,
            'deskripsi_jasa_penerima': deskripsiJasaPenerima,
            'tenggat_pekerjaan': tenggatPekerjaan.toIso8601String(),
          }),
        )
        .timeout(AppConfig.networkTimeout);

    final json = _parseResponse(response, uri);
    return BarterAgreementModel.fromJson(json['data'] as JsonMap);
  }

  Future<List<BarterAgreementModel>> listMyBarters() async {
    final uri = Uri.parse('$_baseUrl/barter');
    final response = await _client
        .get(uri, headers: await _headers())
        .timeout(AppConfig.networkTimeout);

    final json = _parseResponse(response, uri);
    final list = json['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => BarterAgreementModel.fromJson(e as JsonMap))
        .toList(growable: false);
  }

  Future<BarterAgreementModel> getBarterDetail(String barterId) async {
    final uri = Uri.parse('$_baseUrl/barter/$barterId');
    final response = await _client
        .get(uri, headers: await _headers())
        .timeout(AppConfig.networkTimeout);

    final json = _parseResponse(response, uri);
    return BarterAgreementModel.fromJson(json['data'] as JsonMap);
  }

  Future<BarterAgreementModel> acceptBarter(String barterId) async {
    final uri = Uri.parse('$_baseUrl/barter/$barterId/accept');
    final response = await _client
        .post(uri, headers: await _headers())
        .timeout(AppConfig.networkTimeout);

    final json = _parseResponse(response, uri);
    return BarterAgreementModel.fromJson(json['data'] as JsonMap);
  }

  Future<BarterAgreementModel> rejectBarter(String barterId, {String? reason}) async {
    final uri = Uri.parse('$_baseUrl/barter/$barterId/reject');
    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({'alasan': reason ?? 'Ditolak oleh pengguna'}),
        )
        .timeout(AppConfig.networkTimeout);

    final json = _parseResponse(response, uri);
    return BarterAgreementModel.fromJson(json['data'] as JsonMap);
  }

  Future<BarterAgreementModel> startBarter(String barterId) async {
    final uri = Uri.parse('$_baseUrl/barter/$barterId/start');
    final response = await _client
        .post(uri, headers: await _headers())
        .timeout(AppConfig.networkTimeout);

    final json = _parseResponse(response, uri);
    return BarterAgreementModel.fromJson(json['data'] as JsonMap);
  }

  Future<BarterAgreementModel> confirmCompletion(String barterId, {String? note}) async {
    final uri = Uri.parse('$_baseUrl/barter/$barterId/complete');
    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({'catatan': note ?? ''}),
        )
        .timeout(AppConfig.networkTimeout);

    final json = _parseResponse(response, uri);
    return BarterAgreementModel.fromJson(json['data'] as JsonMap);
  }

  Future<void> createReview(
    String barterId, {
    required int rating,
    String? comment,
  }) async {
    final uri = Uri.parse('$_baseUrl/barter/$barterId/reviews');
    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            'rating': rating,
            'komentar': comment ?? 'Ulasan barter berhasil.',
          }),
        )
        .timeout(AppConfig.networkTimeout);

    _parseResponse(response, uri);
  }
}
