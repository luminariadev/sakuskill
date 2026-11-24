import 'dart:async';

import '../../../core/storage/session_store.dart' as secure;

/// Menyimpan token JWT dan identitas pengguna aktif di memori sesi aplikasi,
/// serta mensinkronkan ke [secure.SessionStore] jika diaktifkan di [restore].
class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  secure.SessionStore? _store;
  String? accessToken;
  String? userId;
  String? get id => userId;
  String? fullName;
  String? email;
  String? role;

  String? get userName => fullName;
  String? get userEmail => email;
  String? get userRole => role;

  bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;
  bool get isProvider => role == 'Penyedia Jasa';

  /// Memulihkan sesi tersimpan dari penyimpanan terenkripsi saat app dibuka.
  Future<void> restore(secure.SessionStore store) async {
    _store = store;
    final saved = await store.load();
    if (saved == null) return;
    accessToken = saved.token;
    userId = saved.user.id.isNotEmpty ? saved.user.id : null;
    fullName = saved.user.name.isNotEmpty ? saved.user.name : null;
    email = saved.user.email.isNotEmpty ? saved.user.email : null;
    role ??= 'Penyedia Jasa';
  }

  void save({
    required String token,
    String? id,
    String? name,
    String? userEmail,
    String? userRole,
  }) {
    accessToken = token;
    userId = id;
    fullName = name;
    email = userEmail;
    role = userRole;
    if (_store != null) {
      unawaited(
        _store!.save(
          secure.AuthSession(
            token: token,
            user: secure.SessionUser(
              id: id ?? '',
              name: name ?? '',
              email: userEmail ?? '',
            ),
          ),
        ),
      );
    }
  }

  void clear() {
    accessToken = null;
    userId = null;
    fullName = null;
    email = null;
    role = null;
    if (_store != null) {
      unawaited(_store!.clear());
    }
  }
}
