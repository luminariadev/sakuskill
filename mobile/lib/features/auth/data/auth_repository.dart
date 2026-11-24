import '../../../core/domain/status.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/session_store.dart';

/// Akses autentikasi (FE-01..FE-04). Implementasi menyimpan sesi ke
/// [SessionStore] sehingga token otomatis dipakai [ApiClient].
///
/// Error dilempar sebagai [ApiException]:
/// - `INVALID_CREDENTIALS` (401) → pesan generik di Login (FR-05)
/// - `VALIDATION_ERROR` (422) → `fieldErrors` dengan kunci `nama`, `email`,
///   `kata_sandi`
/// - `EMAIL_ALREADY_EXISTS` (409) → pesan di field email
abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? bio,
  });

  /// Selalu menghapus sesi lokal, walau server tidak bisa dihubungi.
  Future<void> logout();
}

/// `POST /auth/login`, `/auth/register`, `/auth/logout` (API_CONTRACT §Auth).
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, this._session);

  final ApiClient _api;
  final SessionStore _session;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post(
      '/auth/login',
      body: {'email': email.trim(), 'kata_sandi': password},
    );
    return _store(res);
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? bio,
  }) async {
    final res = await _api.post(
      '/auth/register',
      body: {
        'nama': name.trim(),
        'email': email.trim(),
        'kata_sandi': password,
        if (bio != null && bio.trim().isNotEmpty) 'deskripsi_profil': bio.trim(),
      },
    );
    return _store(res);
  }

  @override
  Future<void> logout() async {
    try {
      // Mencabut token di server (revoked_tokens). Gagal jaringan tidak
      // boleh menahan pengguna tetap login di perangkat.
      await _api.post('/auth/logout');
    } on ApiException {
      // diabaikan
    } finally {
      await _session.clear();
    }
  }

  Future<AuthSession> _store(ApiResponse res) async {
    final AuthSession session;
    try {
      session = AuthSession.fromJson(res.dataMap);
    } on TypeError {
      throw ApiException.invalidResponse(statusCode: res.statusCode);
    }
    await _session.save(session);
    return session;
  }
}

/// Mode demo/offline (`USE_MOCK_DATA`, widget test): tanpa jaringan.
/// Sandi < 8 karakter dianggap salah agar alur error Login tetap bisa
/// didemokan.
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository(this._session);

  final SessionStore _session;

  static const _minPassword = 8;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (password.length < _minPassword) {
      throw const ApiException(
        code: 'INVALID_CREDENTIALS',
        message: 'Email atau kata sandi tidak sesuai.',
        statusCode: 401,
      );
    }
    return _save(name: 'Salma Nur Oktavia', email: email);
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? bio,
  }) =>
      _save(name: name, email: email);

  @override
  Future<void> logout() => _session.clear();

  Future<AuthSession> _save({required String name, required String email}) async {
    final session = AuthSession(
      token: 'demo-token',
      user: SessionUser(
        id: 'demo-user',
        name: name.trim(),
        email: email.trim(),
        verification: VerificationStatus.unverified,
      ),
    );
    await _session.save(session);
    return session;
  }
}
