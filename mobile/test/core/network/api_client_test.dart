import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sakuskill/core/network/api_client.dart';
import 'package:sakuskill/core/network/api_exception.dart';

http.Response _json(Object body, int status) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  const base = 'http://localhost:3000/api/v1';

  ApiClient clientFor(
    MockClientHandler handler, {
    TokenProvider? token,
    Duration timeout = const Duration(seconds: 2),
  }) =>
      ApiClient(
        client: MockClient(handler),
        baseUrl: base,
        tokenProvider: token,
        timeout: timeout,
        releaseMode: false,
      );

  group('Permintaan', () {
    test('URL, query, header JSON & Bearer token', () async {
      late http.Request captured;
      final api = clientFor((req) async {
        captured = req;
        return _json({'success': true, 'data': []}, 200);
      }, token: () async => 'tok-123');

      await api.post('/orders', body: {'harga': 50000}, query: {'x': 1, 'skip': null});

      expect(captured.method, 'POST');
      expect(captured.url.toString(), '$base/orders?x=1');
      expect(captured.headers['Authorization'], 'Bearer tok-123');
      expect(captured.headers['Accept'], 'application/json');
      expect(captured.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(captured.body), {'harga': 50000});
    });

    test('tanpa token tidak mengirim Authorization', () async {
      late http.Request captured;
      final api = clientFor((req) async {
        captured = req;
        return _json({'success': true, 'data': null}, 200);
      });
      await api.get('listings'); // tanpa garis miring awal pun valid
      expect(captured.headers.containsKey('Authorization'), isFalse);
      expect(captured.url.path, '/api/v1/listings');
    });
  });

  group('Envelope sukses', () {
    test('data, message, meta', () async {
      final api = clientFor((_) async => _json({
            'success': true,
            'message': 'Berhasil',
            'data': {'id': 'a1'},
            'meta': {'total': 1},
          }, 201));
      final res = await api.post('/x');
      expect(res.statusCode, 201);
      expect(res.message, 'Berhasil');
      expect(res.dataMap['id'], 'a1');
      expect(res.meta['total'], 1);
    });

    test('dataList menerima list langsung atau di bawah kunci', () async {
      final direct = clientFor((_) async => _json({
            'success': true,
            'data': [
              {'id': 1},
              'abaikan-bukan-objek',
            ],
          }, 200));
      expect((await direct.get('/l')).dataList(), [
        {'id': 1},
      ]);

      final nested = clientFor((_) async => _json({
            'success': true,
            'data': {
              'listings': [
                {'id': 2},
              ],
            },
          }, 200));
      expect((await nested.get('/l')).dataList('listings').single['id'], 2);
    });

    test('204 tanpa isi = sukses', () async {
      final api = clientFor((_) async => http.Response('', 204));
      expect((await api.delete('/x')).data, isNull);
    });
  });

  group('Envelope error', () {
    test('422 → fieldErrors tanpa awalan body./query.', () async {
      final api = clientFor((_) async => _json({
            'success': false,
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'Data masukan tidak valid.',
              'details': [
                {'field': 'body.email', 'message': 'Email sudah terdaftar'},
                {'field': 'query.radius_m', 'message': 'Minimal 100'},
                {'field': 'body.email', 'message': 'pesan kedua diabaikan'},
              ],
            },
          }, 422));

      await expectLater(
        api.post('/auth/register'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'VALIDATION_ERROR')
            .having((e) => e.statusCode, 'status', 422)
            .having((e) => e.message, 'message', 'Data masukan tidak valid.')
            .having((e) => e.fieldError('email'), 'email', 'Email sudah terdaftar')
            .having((e) => e.fieldError('radius_m'), 'radius', 'Minimal 100')),
      );
    });

    test('success:false dengan status 200 tetap error', () async {
      final api = clientFor((_) async => _json({
            'success': false,
            'error': {'code': 'CONFLICT', 'message': 'Status sudah berubah'},
          }, 200));
      await expectLater(
        api.post('/orders/1/accept'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'CONFLICT')),
      );
    });

    test('respons bukan JSON / bukan envelope', () async {
      for (final res in [
        http.Response('<html>502</html>', 502),
        _json({'data': []}, 200), // tanpa `success`
      ]) {
        final api = clientFor((_) async => res);
        await expectLater(
          api.get('/x'),
          throwsA(isA<ApiException>()
              .having((e) => e.code, 'code', ApiException.invalidResponseError)),
        );
      }
    });
  });

  group('401 & sesi', () {
    test('memancarkan unauthorizedEvents lalu melempar', () async {
      final api = clientFor((_) async => _json({
            'success': false,
            'error': {'code': 'UNAUTHORIZED', 'message': 'Token kedaluwarsa'},
          }, 401));
      final events = <ApiException>[];
      final sub = api.unauthorizedEvents.listen(events.add);

      await expectLater(
        api.get('/me'),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'unauth', isTrue)),
      );
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));
      await sub.cancel();
    });

    test('401 tanpa body tetap dikenali', () async {
      final api = clientFor((_) async => http.Response('', 401));
      await expectLater(
        api.get('/me'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiException.unauthorized)
            .having((e) => e.message, 'msg', contains('masuk kembali'))),
      );
    });

    test('error selain 401 tidak memancarkan event', () async {
      final api = clientFor((_) async => _json({
            'success': false,
            'error': {'code': 'NOT_FOUND', 'message': 'Tidak ada'},
          }, 404));
      var fired = false;
      final sub = api.unauthorizedEvents.listen((_) => fired = true);
      await expectLater(api.get('/x'), throwsA(isA<ApiException>()));
      await Future<void>.delayed(Duration.zero);
      expect(fired, isFalse);
      await sub.cancel();
    });
  });

  group('Jaringan', () {
    test('ClientException → NETWORK_ERROR', () async {
      final api = clientFor((_) async => throw http.ClientException('putus'));
      await expectLater(
        api.get('/x'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiException.networkError)
            .having((e) => e.isConnectivity, 'conn', isTrue)
            .having((e) => e.message, 'msg', 'Gagal terhubung ke server. Coba lagi.')),
      );
    });

    test('timeout → TIMEOUT', () async {
      final api = clientFor(
        (_) => Completer<http.Response>().future, // tidak pernah selesai
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        api.get('/x'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiException.timeoutError)),
      );
    });
  });

  group('Base URL (FN-02)', () {
    test('rilis menolak HTTP ke host publik', () {
      expect(
        () => ApiClient(baseUrl: 'http://api.sakuskill.id/api/v1', releaseMode: true),
        throwsArgumentError,
      );
    });

    test('rilis mengizinkan HTTPS dan HTTP loopback/emulator', () {
      expect(
        ApiClient(baseUrl: 'https://api.sakuskill.id/api/v1/', releaseMode: true)
            .resolve('/listings')
            .toString(),
        'https://api.sakuskill.id/api/v1/listings',
      );
      for (final host in ['localhost:3000', '10.0.2.2:3000', '127.0.0.1']) {
        expect(
          () => ApiClient(baseUrl: 'http://$host/api/v1', releaseMode: true),
          returnsNormally,
        );
      }
    });

    test('skema selain http/https ditolak', () {
      expect(() => ApiClient(baseUrl: 'ftp://x/api', releaseMode: false),
          throwsArgumentError);
    });
  });

  test('normalizeField', () {
    expect(ApiClient.normalizeField('body.email'), 'email');
    expect(ApiClient.normalizeField('params.id'), 'id');
    expect(ApiClient.normalizeField('body.items.0.harga'), 'items.0.harga');
    expect(ApiClient.normalizeField('nama'), 'nama');
  });
}
