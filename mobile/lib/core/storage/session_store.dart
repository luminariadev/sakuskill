import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/status.dart';

/// Pengguna aktif yang disimpan bersama token (data ringkas untuk header,
/// sapaan, dan guard rute). Profil lengkap tetap diambil dari `GET /me`.
@immutable
class SessionUser {
  const SessionUser({
    required this.id,
    required this.name,
    required this.email,
    this.verification = VerificationStatus.unverified,
    this.photoUrl,
  });

  factory SessionUser.fromJson(Map<String, dynamic> json) => SessionUser(
        id: json['user_id'].toString(),
        name: (json['nama'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        verification: VerificationStatus.tryParse(json['status_verifikasi']) ??
            VerificationStatus.unverified,
        photoUrl: json['foto_url'] as String?,
      );

  final String id;
  final String name;
  final String email;
  final VerificationStatus verification;
  final String? photoUrl;

  /// Nama depan untuk sapaan, mis. "Salma".
  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  Map<String, dynamic> toJson() => {
        'user_id': id,
        'nama': name,
        'email': email,
        'status_verifikasi': verification.toJson(),
        if (photoUrl != null) 'foto_url': photoUrl,
      };

  @override
  bool operator ==(Object other) =>
      other is SessionUser &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.verification == verification &&
      other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(id, name, email, verification, photoUrl);
}

/// Sesi login: token Bearer + pengguna aktif.
@immutable
class AuthSession {
  const AuthSession({required this.token, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        token: json['token'] as String,
        user: SessionUser.fromJson(json['user'] as Map<String, dynamic>),
      );

  final String token;
  final SessionUser user;

  Map<String, dynamic> toJson() => {'token': token, 'user': user.toJson()};

  @override
  bool operator ==(Object other) =>
      other is AuthSession && other.token == token && other.user == user;

  @override
  int get hashCode => Object.hash(token, user);
}

/// Penyimpanan sesi (T-07, FE-03/FE-04, FN-04).
///
/// - Token TIDAK pernah disimpan di SharedPreferences; implementasi produksi
///   [SecureSessionStore] memakai Keychain/EncryptedSharedPreferences/WebCrypto.
/// - [session] bisa didengarkan (mis. oleh route guard) untuk bereaksi saat
///   login/logout.
/// - [token] dipakai `ApiClient(tokenProvider: store.token)`.
abstract class SessionStore {
  /// Sesi saat ini; null = belum login. Valid setelah [load] selesai.
  ValueListenable<AuthSession?> get session;

  /// Membaca sesi tersimpan (dipanggil sekali saat aplikasi mulai).
  Future<AuthSession?> load();

  Future<void> save(AuthSession session);

  /// Logout: hapus token & pengguna (FE-04).
  Future<void> clear();

  /// Token untuk header Authorization; null bila belum login.
  FutureOr<String?> token() => session.value?.token;

  bool get isLoggedIn => session.value != null;
}

/// Implementasi produksi berbasis `flutter_secure_storage`.
class SecureSessionStore extends SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Kunci penyimpanan (satu entri JSON berisi token + pengguna).
  static const String storageKey = 'sakuskill.session.v1';

  final FlutterSecureStorage _storage;
  final ValueNotifier<AuthSession?> _session = ValueNotifier(null);

  @override
  ValueListenable<AuthSession?> get session => _session;

  @override
  Future<AuthSession?> load() async {
    final raw = await _storage.read(key: storageKey);
    if (raw == null) return _session.value = null;
    try {
      return _session.value =
          AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object catch (error) {
      // Data rusak/format lama → buang dan minta login ulang.
      debugPrint('[Session] sesi tersimpan tidak valid, dihapus: $error');
      await _storage.delete(key: storageKey);
      return _session.value = null;
    }
  }

  @override
  Future<void> save(AuthSession session) async {
    await _storage.write(key: storageKey, value: jsonEncode(session.toJson()));
    _session.value = session;
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: storageKey);
    _session.value = null;
  }
}

/// Sesi di memori untuk tes dan mode offline/demo (tidak persisten).
class InMemorySessionStore extends SessionStore {
  InMemorySessionStore([AuthSession? initial])
      : _session = ValueNotifier(initial);

  final ValueNotifier<AuthSession?> _session;

  @override
  ValueListenable<AuthSession?> get session => _session;

  @override
  Future<AuthSession?> load() async => _session.value;

  @override
  Future<void> save(AuthSession session) async => _session.value = session;

  @override
  Future<void> clear() async => _session.value = null;
}
