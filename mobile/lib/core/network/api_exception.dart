/// Kegagalan panggilan API yang sudah dinormalisasi (T-06).
///
/// - [code]: kode dari envelope (`VALIDATION_ERROR`, `UNAUTHORIZED`, …) atau
///   kode klien (`NETWORK_ERROR`, `TIMEOUT`, `INVALID_RESPONSE`).
/// - [message]: pesan siap tampil berbahasa Indonesia (FN-06).
/// - [fieldErrors]: `error.details[]` dipetakan ke nama field form tanpa
///   awalan `body.` / `query.` / `params.`, siap dipasang ke
///   `SakuTextField.errorText`.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  /// Server tidak terjangkau / koneksi putus (NFR-16).
  const ApiException.network()
    : this(
        code: networkError,
        message: 'Gagal terhubung ke server. Coba lagi.',
      );

  /// Server tidak menjawab dalam batas waktu.
  const ApiException.timeout()
    : this(
        code: timeoutError,
        message: 'Server terlalu lama merespons. Coba lagi.',
      );

  /// Respons bukan envelope `{success, data|error}` yang valid.
  const ApiException.invalidResponse({int? statusCode})
    : this(
        code: invalidResponseError,
        message: 'Respons server tidak dapat dibaca. Coba lagi nanti.',
        statusCode: statusCode,
      );

  static const String networkError = 'NETWORK_ERROR';
  static const String timeoutError = 'TIMEOUT';
  static const String invalidResponseError = 'INVALID_RESPONSE';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String validationError = 'VALIDATION_ERROR';

  final String code;
  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  /// Sesi tidak sah/kedaluwarsa → aplikasi harus logout (FE-03).
  bool get isUnauthorized => statusCode == 401 || code == unauthorized;

  /// Gangguan jaringan (bukan penolakan server) → aksi boleh diulang.
  bool get isConnectivity => code == networkError || code == timeoutError;

  /// Pesan error untuk satu field form, mis. `fieldError('email')`.
  String? fieldError(String field) => fieldErrors[field];

  @override
  String toString() => 'ApiException($code, ${statusCode ?? '-'}): $message';
}
