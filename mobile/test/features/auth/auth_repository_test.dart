import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sakuskill/core/domain/status.dart';
import 'package:sakuskill/core/network/api_client.dart';
import 'package:sakuskill/core/network/api_exception.dart';
import 'package:sakuskill/core/storage/session_store.dart';
import 'package:sakuskill/features/auth/data/auth_repository.dart';

http.Response _json(Object body, int status) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Bentuk respons persis dari backend develop (`POST /auth/register|login`).
Map<String, Object?> _authBody(String token) => {
      'success': true,
      'message': 'Login berhasil.',
      'data': {
        'user': {
          'user_id': 'c0713a04-7d20-45e9-9ac7-993a15a7ba46',
          'nama': 'Uji Integrasi',
          'email': 'uji@example.com',
          'peran': 'Penyedia Jasa',
          'status_verifikasi': 'Belum Terverifikasi',
          'deskripsi_profil': null,
          'capabilities': {'can_buy_services': true},
        },
        'token': token,
      },
    };

void main() {
  late InMemorySessionStore session;
  late List<http.Request> requests;

  ApiAuthRepository repoFor(MockClientHandler handler) {
    requests = [];
    final api = ApiClient(
      client: MockClient((req) {
        requests.add(req);
        return handler(req);
      }),
      baseUrl: 'http://localhost:3000/api/v1',
      tokenProvider: session.token,
      releaseMode: false,
    );
    return ApiAuthRepository(api, session);
  }

  setUp(() => session = InMemorySessionStore());

  test('login mengirim email + kata_sandi lalu menyimpan sesi', () async {
    final repo = repoFor((_) async => _json(_authBody('jwt-1'), 200));

    final result = await repo.login(email: ' uji@example.com ', password: 'Rahasia123');

    expect(requests.single.url.path, '/api/v1/auth/login');
    expect(jsonDecode(requests.single.body),
        {'email': 'uji@example.com', 'kata_sandi': 'Rahasia123'});
    expect(result.token, 'jwt-1');
    expect(result.user.verification, VerificationStatus.unverified);
    expect(session.session.value, result);
    expect(await session.token(), 'jwt-1');
  });

  test('register memetakan field API dan tidak mengirim bio kosong', () async {
    final repo = repoFor((_) async => _json(_authBody('jwt-2'), 201));

    await repo.register(name: 'Uji', email: 'uji@example.com', password: 'Rahasia123', bio: '  ');

    expect(requests.single.url.path, '/api/v1/auth/register');
    expect(jsonDecode(requests.single.body),
        {'nama': 'Uji', 'email': 'uji@example.com', 'kata_sandi': 'Rahasia123'});
    expect(session.isLoggedIn, isTrue);
  });

  test('401 INVALID_CREDENTIALS dilempar dan sesi tetap kosong', () async {
    final repo = repoFor((_) async => _json({
          'success': false,
          'error': {'code': 'INVALID_CREDENTIALS', 'message': 'Email atau kata sandi salah.'},
        }, 401));

    await expectLater(
      repo.login(email: 'uji@example.com', password: 'salah'),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', 'INVALID_CREDENTIALS')),
    );
    expect(session.isLoggedIn, isFalse);
  });

  test('422 VALIDATION_ERROR → fieldErrors tanpa prefix body.', () async {
    final repo = repoFor((_) async => _json({
          'success': false,
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'Data masukan tidak valid.',
            'details': [
              {'field': 'body.email', 'message': 'Format alamat email tidak valid.'},
              {'field': 'body.kata_sandi', 'message': 'Kata sandi minimal 8 karakter.'},
            ],
          },
        }, 422));

    await expectLater(
      repo.register(name: 'Uji', email: 'x', password: '1'),
      throwsA(isA<ApiException>().having((e) => e.fieldErrors, 'fieldErrors', {
        'email': 'Format alamat email tidak valid.',
        'kata_sandi': 'Kata sandi minimal 8 karakter.',
      })),
    );
  });

  test('respons sukses tanpa token dianggap respons tidak valid', () async {
    final repo = repoFor((_) async => _json({
          'success': true,
          'data': {'user': {'user_id': 'u1'}},
        }, 200));

    await expectLater(
      repo.login(email: 'uji@example.com', password: 'Rahasia123'),
      throwsA(isA<ApiException>().having(
          (e) => e.code, 'code', ApiException.invalidResponseError)),
    );
    expect(session.isLoggedIn, isFalse);
  });

  test('logout memanggil server dengan Bearer lalu menghapus sesi', () async {
    final repo = repoFor((_) async => _json({'success': true, 'data': null}, 200));
    await session.save(AuthSession.fromJson(
        (_authBody('jwt-3')['data'] as Map).cast<String, dynamic>()));

    await repo.logout();

    expect(requests.single.url.path, '/api/v1/auth/logout');
    expect(requests.single.headers['Authorization'], 'Bearer jwt-3');
    expect(session.isLoggedIn, isFalse);
  });

  test('logout tetap menghapus sesi saat server tidak terjangkau', () async {
    final repo = repoFor((_) async => throw http.ClientException('offline'));
    await session.save(AuthSession.fromJson(
        (_authBody('jwt-4')['data'] as Map).cast<String, dynamic>()));

    await repo.logout();

    expect(session.isLoggedIn, isFalse);
  });

  group('DemoAuthRepository', () {
    test('sandi < 8 → INVALID_CREDENTIALS; sandi valid → sesi demo', () async {
      final demo = DemoAuthRepository(session);
      await expectLater(demo.login(email: 'a@b.co', password: '123'),
          throwsA(isA<ApiException>()));
      final s = await demo.login(email: 'a@b.co', password: '12345678');
      expect(session.session.value, s);
    });
  });
}
