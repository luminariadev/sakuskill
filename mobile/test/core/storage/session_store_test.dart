import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sakuskill/core/domain/status.dart';
import 'package:sakuskill/core/network/api_client.dart';
import 'package:sakuskill/core/network/api_exception.dart';
import 'package:sakuskill/core/storage/session_store.dart';
import 'package:sakuskill/features/auth/data/auth_session.dart' as auth_session;

const _salma = AuthSession(
  token: 'tok-abc',
  user: SessionUser(
    id: 'u-1',
    name: 'Salma Nur Oktavia',
    email: 'salma@gmail.com',
    verification: VerificationStatus.verified,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthSession JSON', () {
    test('round-trip', () {
      final json = jsonDecode(jsonEncode(_salma.toJson())) as Map<String, dynamic>;
      expect(AuthSession.fromJson(json), _salma);
      expect(json['user']['status_verifikasi'], 'Terverifikasi');
    });

    test('firstName untuk sapaan', () {
      expect(_salma.user.firstName, 'Salma');
    });

    test('status verifikasi asing → Belum Terverifikasi', () {
      final user = SessionUser.fromJson(const {
        'user_id': 7,
        'nama': 'Dimas',
        'email': 'd@x.id',
        'status_verifikasi': '???',
      });
      expect(user.id, '7');
      expect(user.verification, VerificationStatus.unverified);
    });
  });

  group('SecureSessionStore', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('kosong → belum login', () async {
      final store = SecureSessionStore();
      expect(await store.load(), isNull);
      expect(store.isLoggedIn, isFalse);
      expect(await store.token(), isNull);
    });

    test('simpan lalu dipulihkan oleh instance baru (sesi bertahan)', () async {
      await SecureSessionStore().save(_salma);

      final reopened = SecureSessionStore();
      expect(await reopened.load(), _salma);
      expect(await reopened.token(), 'tok-abc');
      expect(reopened.isLoggedIn, isTrue);
    });

    test('clear menghapus dari penyimpanan (logout)', () async {
      final store = SecureSessionStore();
      await store.save(_salma);
      await store.clear();

      expect(store.session.value, isNull);
      expect(await SecureSessionStore().load(), isNull);
    });

    test('data rusak dibuang, bukan crash', () async {
      FlutterSecureStorage.setMockInitialValues(
          {SecureSessionStore.storageKey: '{bukan json'});
      final store = SecureSessionStore();
      expect(await store.load(), isNull);
      expect(await const FlutterSecureStorage().read(key: SecureSessionStore.storageKey),
          isNull);
    });

    test('session dapat didengarkan', () async {
      final store = SecureSessionStore();
      final seen = <AuthSession?>[];
      store.session.addListener(() => seen.add(store.session.value));
      await store.save(_salma);
      await store.clear();
      expect(seen, [_salma, null]);
    });
  });

  test('InMemorySessionStore', () async {
    final store = InMemorySessionStore(_salma);
    expect(await store.load(), _salma);
    await store.clear();
    expect(store.isLoggedIn, isFalse);
  });

  group('Integrasi DI', () {
    test('ApiClient memakai token dari sesi', () async {
      final store = InMemorySessionStore(_salma);
      late http.Request captured;
      final api = ApiClient(
        client: MockClient((req) async {
          captured = req;
          return http.Response('{"success":true,"data":null}', 200);
        }),
        baseUrl: 'http://localhost:3000/api/v1',
        tokenProvider: store.token,
        releaseMode: false,
      );
      await api.get('/me');
      expect(captured.headers['Authorization'], 'Bearer tok-abc');

      await store.clear();
      await api.get('/me');
      expect(captured.headers.containsKey('Authorization'), isFalse);
    });

    test('401 dari server menghapus sesi (logout otomatis)', () async {
      final store = InMemorySessionStore(_salma);
      final api = ApiClient(
        client: MockClient((_) async => http.Response('', 401)),
        baseUrl: 'http://localhost:3000/api/v1',
        tokenProvider: store.token,
        releaseMode: false,
      );
      final sub = api.unauthorizedEvents.listen((_) {
        unawaited(store.clear());
      });
      addTearDown(sub.cancel);

      await expectLater(api.get('/me'), throwsA(isA<ApiException>()));
      await Future<void>.delayed(Duration.zero);
      expect(store.isLoggedIn, isFalse);
    });

    test('AuthSession.instance.restore memulihkan sesi tersimpan', () async {
      final store = InMemorySessionStore(_salma);
      final appSession = auth_session.AuthSession.instance;
      addTearDown(appSession.clear);

      await appSession.restore(store);
      expect(appSession.isLoggedIn, isTrue);

      appSession.clear();
      expect(appSession.isLoggedIn, isFalse);
      expect(store.isLoggedIn, isFalse);
    });
  });
}
