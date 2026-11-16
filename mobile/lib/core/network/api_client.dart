import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

/// Menyediakan token sesi saat ini (null = belum login). Diisi
/// `SessionStore` setelah T-07; untuk sekarang default tanpa token.
typedef TokenProvider = FutureOr<String?> Function();

/// Isi envelope sukses `{success: true, message, data, meta}`.
class ApiResponse {
  const ApiResponse({
    required this.data,
    this.message,
    this.meta = const {},
    required this.statusCode,
  });

  final Object? data;
  final String? message;
  final Map<String, dynamic> meta;
  final int statusCode;

  /// `data` sebagai objek; melempar [ApiException.invalidResponse] bila bukan.
  Map<String, dynamic> get dataMap {
    final d = data;
    if (d is Map<String, dynamic>) return d;
    throw ApiException.invalidResponse(statusCode: statusCode);
  }

  /// `data` sebagai daftar objek. Menerima `data: [...]` atau
  /// `data: {<listKey>: [...]}`; null/absen → daftar kosong.
  List<Map<String, dynamic>> dataList([String? listKey]) {
    final d = data;
    final raw = d is List
        ? d
        : (d is Map<String, dynamic> && listKey != null ? d[listKey] : null);
    if (raw == null) return const [];
    if (raw is! List) {
      throw ApiException.invalidResponse(statusCode: statusCode);
    }
    return raw.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}

/// Satu-satunya pintu panggilan REST aplikasi (T-06, `docs/API_CONTRACT.md`).
///
/// - Base URL dari [AppConfig.apiBaseUrl]; HTTPS wajib di build rilis kecuali
///   host loopback/emulator (FN-02).
/// - Header `Authorization: Bearer <token>` bila [TokenProvider] memberi token.
/// - Parsing envelope `{success, message, data, meta}` / `{success:false, error}`.
/// - Semua kegagalan dilempar sebagai [ApiException] (termasuk jaringan &
///   timeout), sehingga repository cukup menangkap satu tipe.
/// - Respons 401 memancarkan [unauthorizedEvents] agar sesi di-logout.
///
/// ```dart
/// final res = await api.get('/listings', query: {'radius_m': '2000'});
/// final items = res.dataList('listings');
/// ```
class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
    this.timeout = AppConfig.networkTimeout,
    TokenProvider? tokenProvider,
    bool? releaseMode,
  }) : _client = client ?? http.Client(),
       _baseUri = _validatedBase(
         baseUrl ?? AppConfig.apiBaseUrl,
         releaseMode ?? kReleaseMode,
       ),
       _token = tokenProvider ?? _noToken;

  /// Klien tanpa jaringan untuk mode offline/tes: setiap permintaan langsung
  /// gagal sebagai [ApiException.network].
  factory ApiClient.offline() => ApiClient(
    client: _OfflineHttpClient(),
    baseUrl: 'http://localhost/offline',
    releaseMode: false,
  );

  final http.Client _client;
  final Uri _baseUri;
  final TokenProvider _token;
  final Duration timeout;
  final StreamController<ApiException> _unauthorized =
      StreamController<ApiException>.broadcast();

  static String? _noToken() => null;

  /// Host yang boleh memakai HTTP polos (debug lokal & emulator Android).
  static const Set<String> insecureHostsAllowed = {
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
  };

  /// Dipancarkan setiap server membalas 401. `SessionStore`/AuthController
  /// mendengarkan ini untuk menghapus token dan kembali ke Login.
  Stream<ApiException> get unauthorizedEvents => _unauthorized.stream;

  Uri get baseUri => _baseUri;

  static Uri _validatedBase(String raw, bool release) {
    final uri = Uri.parse(
      raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw,
    );
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      throw ArgumentError.value(raw, 'baseUrl', 'Skema harus http atau https');
    }
    if (release &&
        uri.scheme == 'http' &&
        !insecureHostsAllowed.contains(uri.host)) {
      throw ArgumentError.value(
        raw,
        'baseUrl',
        'Build rilis wajib HTTPS (NFR-06). HTTP hanya untuk localhost/10.0.2.2.',
      );
    }
    return uri;
  }

  /// `{base}/path?query`. [path] diawali `/`, mis. `/orders/123`.
  Uri resolve(String path, [Map<String, Object?>? query]) {
    final cleaned = path.startsWith('/') ? path : '/$path';
    final params = <String, String>{
      for (final e in (query ?? const {}).entries)
        if (e.value != null) e.key: e.value.toString(),
    };
    return _baseUri.replace(
      path: '${_baseUri.path}$cleaned',
      queryParameters: params.isEmpty ? null : params,
    );
  }

  Future<ApiResponse> get(String path, {Map<String, Object?>? query}) =>
      _send('GET', path, query: query);

  Future<ApiResponse> post(
    String path, {
    Object? body,
    Map<String, Object?>? query,
  }) => _send('POST', path, query: query, body: body);

  Future<ApiResponse> patch(
    String path, {
    Object? body,
    Map<String, Object?>? query,
  }) => _send('PATCH', path, query: query, body: body);

  Future<ApiResponse> delete(String path, {Map<String, Object?>? query}) =>
      _send('DELETE', path, query: query);

  Future<ApiResponse> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
  }) async {
    final uri = resolve(path, query);
    final token = await _token();
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json; charset=utf-8',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      });
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw const ApiException.timeout();
    } on http.ClientException {
      // package:http membungkus SocketException (IO) dan kegagalan XHR (Web)
      // menjadi ClientException, jadi tidak perlu dart:io (aman untuk Web).
      throw const ApiException.network();
    }

    return _parse(response);
  }

  ApiResponse _parse(http.Response response) {
    final status = response.statusCode;
    Object? json;
    if (response.bodyBytes.isNotEmpty) {
      try {
        json = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        json = null;
      }
    }

    final envelope = json is Map<String, dynamic> ? json : null;
    final success = envelope?['success'];

    if (status >= 200 && status < 300 && success == true) {
      final meta = envelope!['meta'];
      return ApiResponse(
        data: envelope['data'],
        message: envelope['message'] as String?,
        meta: meta is Map<String, dynamic> ? meta : const {},
        statusCode: status,
      );
    }

    // 204 tanpa isi tetap dianggap sukses.
    if (status == 204 && envelope == null) {
      return ApiResponse(data: null, statusCode: status);
    }

    final error = _errorFrom(envelope, status);
    if (error.isUnauthorized) _unauthorized.add(error);
    throw error;
  }

  static ApiException _errorFrom(Map<String, dynamic>? envelope, int status) {
    final err = envelope?['error'];
    if (err is! Map<String, dynamic>) {
      if (status == 401) {
        return const ApiException(
          code: ApiException.unauthorized,
          message: 'Sesi Anda berakhir. Silakan masuk kembali.',
          statusCode: 401,
        );
      }
      return ApiException.invalidResponse(statusCode: status);
    }

    final fieldErrors = <String, String>{};
    final details = err['details'];
    if (details is List) {
      for (final d in details.whereType<Map<String, dynamic>>()) {
        final field = d['field'];
        final message = d['message'];
        if (field is String && message is String) {
          // Pertahankan pesan pertama per field.
          fieldErrors.putIfAbsent(normalizeField(field), () => message);
        }
      }
    }

    return ApiException(
      code:
          (err['code'] as String?) ??
          (status == 401 ? ApiException.unauthorized : 'HTTP_$status'),
      message: (err['message'] as String?) ?? 'Terjadi kesalahan. Coba lagi.',
      statusCode: status,
      fieldErrors: fieldErrors,
    );
  }

  /// `body.email` → `email`, `query.radius_m` → `radius_m`,
  /// `body.items.0.harga` → `items.0.harga`.
  static String normalizeField(String field) =>
      field.replaceFirst(RegExp(r'^(body|query|params)\.'), '');

  /// Tutup koneksi & stream (dipanggil saat aplikasi dihentikan / di tes).
  void close() {
    _client.close();
    _unauthorized.close();
  }
}

class _OfflineHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Future.error(http.ClientException('Mode offline', request.url));
}
