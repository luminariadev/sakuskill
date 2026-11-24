// Uji kontrak FE ↔ backend sungguhan (bukan mock).
//
// Dilewati kecuali BACKEND_URL diisi. Contoh (backend `npm start` di :3000):
//
//   flutter test test/integration/backend_live_test.dart \
//     --dart-define=BACKEND_URL=http://127.0.0.1:3000/api/v1
//
// Membuat akun + gig uji dengan email unik, lalu menghapus gig-nya.
@Tags(['live'])
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakuskill/core/config/app_config.dart';
import 'package:sakuskill/core/domain/status.dart';
import 'package:sakuskill/core/network/api_client.dart';
import 'package:sakuskill/core/network/api_exception.dart';
import 'package:sakuskill/core/storage/session_store.dart';
import 'package:sakuskill/features/auth/data/auth_repository.dart';
import 'package:sakuskill/features/discovery/data/datasources/discovery_local_data_source.dart';
import 'package:sakuskill/features/discovery/data/datasources/discovery_remote_data_source.dart';
import 'package:sakuskill/features/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:sakuskill/features/discovery/domain/entities/discovery_filter.dart';

const _backendUrl = String.fromEnvironment('BACKEND_URL');

void main() {
  final skip = _backendUrl.isEmpty
      ? 'Set --dart-define=BACKEND_URL=http://127.0.0.1:3000/api/v1'
      : null;

  late InMemorySessionStore session;
  late ApiClient api;
  late DiscoveryRepositoryImpl discoveryRepo;
  late ApiAuthRepository auth;
  late StreamSubscription<ApiException> unauthSub;

  final email = 'fe.live.${DateTime.now().millisecondsSinceEpoch}@example.com';
  const password = 'RahasiaUji123!';
  String? gigId;

  setUpAll(() {
    session = InMemorySessionStore();
    api = ApiClient(
      baseUrl: _backendUrl.isEmpty ? 'http://127.0.0.1:3000/api/v1' : _backendUrl,
      tokenProvider: session.token,
      releaseMode: false,
    );
    unauthSub = api.unauthorizedEvents.listen((_) => session.clear());
    auth = ApiAuthRepository(api, session);
    discoveryRepo = DiscoveryRepositoryImpl(
      remote: DiscoveryRemoteDataSource(baseUrl: _backendUrl),
      local: const DiscoveryLocalDataSource(),
    );
  });

  tearDownAll(() async {
    if (gigId != null && session.isLoggedIn) {
      try {
        await api.delete('/gigs/$gigId');
      } on ApiException {
        // dibiarkan: data uji di DB lokal
      }
    }
    await unauthSub.cancel();
    api.close();
  });

  test('health: server + PostGIS hidup', () async {
    final res = await api.get('/health');
    final db = res.dataMap['database'] as Map<String, dynamic>;
    expect(db['connected'], isTrue);
    expect(db['postgis_enabled'], isTrue);
  }, skip: skip);

  test('register → sesi tersimpan, status verifikasi dari enum baku', () async {
    final s = await auth.register(name: 'Uji FE Live', email: email, password: password);
    expect(s.token, isNotEmpty);
    expect(s.user.email, email);
    expect(s.user.verification, VerificationStatus.unverified);
    expect(session.session.value, s);
  }, skip: skip);

  test('register email sama → 409 EMAIL_ALREADY_EXISTS', () async {
    await expectLater(
      auth.register(name: 'Uji FE Live', email: email, password: password),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', 'EMAIL_ALREADY_EXISTS')
          .having((e) => e.statusCode, 'status', 409)),
    );
  }, skip: skip);

  test('register tidak valid → 422 dengan fieldErrors per field', () async {
    await expectLater(
      auth.register(name: 'A', email: 'bukan-email', password: '1'),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', ApiException.validationError)
          .having((e) => e.fieldErrors.keys, 'fields',
              containsAll(['nama', 'email', 'kata_sandi']))),
    );
  }, skip: skip);

  test('login salah → 401 INVALID_CREDENTIALS tanpa memicu logout', () async {
    final before = session.session.value;
    await expectLater(
      auth.login(email: email, password: 'salah-total'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
    await pumpEventQueue();
    expect(session.session.value, before);
  }, skip: skip);

  test('login benar → token baru dipakai GET /users/me', () async {
    final s = await auth.login(email: email, password: password);
    final me = await api.get('/users/me');
    final user = me.dataMap['user'] as Map<String, dynamic>? ?? me.dataMap;
    expect(user['email'], email);
    expect(s.user.name, 'Uji FE Live');
  }, skip: skip);

  test('gig baru muncul di Discovery dan ter-parse ke entitas', () async {
    final created = await api.post('/gigs', body: {
      'judul': 'Gig Uji Integrasi FE',
      'deskripsi': 'Dibuat otomatis oleh backend_live_test.dart',
      'skill_id': 1,
      'harga': 45000,
      'latitude': AppConfig.campusCenter.latitude + 0.0005,
      'longitude': AppConfig.campusCenter.longitude,
      'tipe_penawaran': 'Berbayar dan Barter',
      'deskripsi_imbalan_barter': 'Tukar desain poster',
    });
    final gig = created.dataMap['gig'] as Map<String, dynamic>? ?? created.dataMap;
    gigId = gig['listing_id'].toString();

    final listings = await DiscoveryRemoteDataSource(baseUrl: _backendUrl)
        .fetchNearby(const DiscoveryFilter(radiusMeters: 1000));
    final mine = listings.firstWhere((l) => l.id == gigId);
    expect(mine.title, 'Gig Uji Integrasi FE');
    expect(mine.price, 45000);
    expect(mine.offerType, OfferType.paidAndBarter);
    expect(mine.location, isNotNull);
    expect(mine.distanceMeters, lessThan(200));
    expect(mine.barterWant, 'Tukar desain poster');
    expect(mine.rating, isNull);

    // Lewat repository: data asli dari server, bukan fallback lokal.
    final viaRepo = await discoveryRepo
        .searchNearby(const DiscoveryFilter(radiusMeters: 1000));
    expect(viaRepo.listings.any((l) => l.id == gigId), isTrue);
    expect(viaRepo.isFallback, isFalse);
  }, skip: skip);

  test('logout mencabut token: request lama 401 dan sesi lokal kosong', () async {
    final oldToken = await session.token();
    await api.delete('/gigs/$gigId');
    gigId = null;
    await auth.logout();
    expect(session.isLoggedIn, isFalse);

    final probe = ApiClient(
      baseUrl: _backendUrl,
      tokenProvider: () => oldToken,
      releaseMode: false,
    );
    await expectLater(
      probe.get('/users/me'),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', isTrue)),
    );
    probe.close();
  }, skip: skip);

  test('401 dari server menghapus sesi lewat AppDependencies', () async {
    await session.save(const AuthSession(
      token: 'token-palsu',
      user: SessionUser(id: 'x', name: 'X', email: 'x@example.com'),
    ));
    await expectLater(api.get('/users/me'), throwsA(isA<ApiException>()));
    await pumpEventQueue();
    expect(session.isLoggedIn, isFalse);
  }, skip: skip);
}
