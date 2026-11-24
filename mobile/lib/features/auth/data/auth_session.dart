import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/storage/session_store.dart' as secure;

/// Menyimpan token JWT dan identitas pengguna aktif di memori sesi aplikasi,
/// serta mensinkronkan ke [secure.SessionStore] jika diaktifkan di [bind]/[restore].
class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  final StreamController<void> _unauthorizedController =
      StreamController<void>.broadcast();
  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  secure.SessionStore? _store;
  VoidCallback? _storeListener;
  String? accessToken;
  String? userId;
  String? get id => userId;
  String? fullName;
  String? email;
  String? role;
  String? photoUrl;
  final ValueNotifier<String?> photoUrlNotifier = ValueNotifier<String?>(null);

  String? get userName => fullName;
  String? get userEmail => email;
  String? get userRole => role;

  bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;
  bool get isProvider => role == 'Penyedia Jasa';

  void _setPhoto(String? value) {
    final clean = (value != null && value.trim().isNotEmpty) ? value.trim() : null;
    photoUrl = clean;
    photoUrlNotifier.value = clean;
  }

  void _applySecure(secure.AuthSession? saved) {
    if (saved == null) {
      accessToken = null;
      userId = null;
      fullName = null;
      email = null;
      role = null;
      _setPhoto(null);
      return;
    }
    accessToken = saved.token;
    userId = saved.user.id.isNotEmpty ? saved.user.id : null;
    fullName = saved.user.name.isNotEmpty ? saved.user.name : null;
    email = saved.user.email.isNotEmpty ? saved.user.email : null;
    role ??= 'Penyedia Jasa';
    _setPhoto(saved.user.photoUrl);
  }

  void updatePhotoUrl(String? url) {
    _setPhoto(url);
    final store = _store;
    final token = accessToken;
    if (store == null || token == null || token.isEmpty) return;
    final current = store.session.value;
    final updatedSession = secure.AuthSession(
      token: current?.token ?? token,
      user: secure.SessionUser(
        id: userId ?? current?.user.id ?? '',
        name: fullName ?? current?.user.name ?? '',
        email: email ?? current?.user.email ?? '',
        verification: current?.user.verification ??
            const secure.SessionUser(id: '', name: '', email: '').verification,
        photoUrl: photoUrl,
      ),
    );
    unawaited(store.save(updatedSession).catchError((_) {}));
  }

  /// Mengikat [store] agar setiap perubahan dari repository auth/API
  /// langsung tercermin di [AuthSession.instance].
  void bind(secure.SessionStore store) {
    if (identical(_store, store)) {
      _applySecure(store.session.value);
      return;
    }
    if (_storeListener != null) {
      _store?.session.removeListener(_storeListener!);
    }
    _store = store;
    _applySecure(store.session.value);
    _storeListener = () => _applySecure(store.session.value);
    store.session.addListener(_storeListener!);
  }

  /// Memulihkan sesi tersimpan dari penyimpanan terenkripsi saat app dibuka.
  Future<void> restore(secure.SessionStore store) async {
    bind(store);
    final saved = await store.load();
    _applySecure(saved);
  }

  /// Menghapus sesi aktif dan memicu navigasi ke Login saat menerima 401.
  void notifyUnauthorized() {
    if (!isLoggedIn) return;
    clear();
    _unauthorizedController.add(null);
  }

  void save({
    required String token,
    String? id,
    String? name,
    String? userEmail,
    String? userRole,
    String? userPhotoUrl,
  }) {
    accessToken = token;
    userId = id;
    fullName = name;
    email = userEmail;
    role = userRole;
    _setPhoto(userPhotoUrl);
    if (_store != null) {
      unawaited(
        _store!
            .save(
              secure.AuthSession(
                token: token,
                user: secure.SessionUser(
                  id: id ?? '',
                  name: name ?? '',
                  email: userEmail ?? '',
                  photoUrl: photoUrl,
                ),
              ),
            )
            .catchError((_) {}),
      );
    }
  }

  void clear() {
    accessToken = null;
    userId = null;
    fullName = null;
    email = null;
    role = null;
    _setPhoto(null);
    if (_store != null) {
      unawaited(_store!.clear().catchError((_) {}));
    }
  }
}
