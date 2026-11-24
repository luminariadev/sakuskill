import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/auth_session.dart' as legacy_auth;
import '../../features/discovery/data/datasources/discovery_local_data_source.dart';
import '../../features/discovery/data/datasources/discovery_remote_data_source.dart';
import '../../features/discovery/data/repositories/discovery_repository_impl.dart';
import '../../features/discovery/domain/entities/discovery_filter.dart';
import '../../features/discovery/domain/repositories/discovery_repository.dart';
import '../../features/discovery/domain/usecases/discovery_usecases.dart';
import '../../features/discovery/presentation/controllers/discovery_controller.dart';
import '../../features/escrow/data/datasources/escrow_local_data_source.dart';
import '../../features/escrow/data/datasources/escrow_remote_data_source.dart';
import '../../features/escrow/domain/repositories/escrow_repository.dart';
import '../../features/escrow/domain/repositories/escrow_repository_impl.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../storage/session_store.dart';

/// Composition root (dependency injection manual, tanpa paket tambahan).
class AppDependencies {
  AppDependencies({
    required this.api,
    required this.session,
    required this.discoveryRepository,
    required this.escrowRepository,
    required this.authRepository,
  }) {
    // Server menolak token (401) → sesi dihapus; route guard (M2) yang
    // mendengarkan `session.session` akan membawa pengguna ke Login.
    _unauthorizedSub = api.unauthorizedEvents.listen((_) => session.clear());
  }

  factory AppDependencies.production() {
    final session = SecureSessionStore();
    final api = ApiClient(tokenProvider: session.token);
    return AppDependencies(
      api: api,
      session: session,
      discoveryRepository: DiscoveryRepositoryImpl(
        remote: DiscoveryRemoteDataSource(api),
        local: const DiscoveryLocalDataSource(),
        forceLocal: AppConfig.useMockData,
      ),
      escrowRepository: EscrowRepositoryImpl(
        remote: EscrowRemoteDataSource(
          tokenProvider: () async =>
              session.token() ?? legacy_auth.AuthSession.instance.accessToken,
        ),
        local: const EscrowLocalDataSource(),
        forceLocal: AppConfig.useMockData,
      ),
      authRepository: AppConfig.useMockData
          ? DemoAuthRepository(session)
          : ApiAuthRepository(api, session),
    );
  }

  /// Dipakai widget test: selalu data lokal, tanpa jaringan sama sekali
  /// (ApiClient offline langsung gagal bila tetap dipanggil). Sesi di
  /// memori; isi [initialSession] untuk menguji layar yang butuh login.
  factory AppDependencies.offline({AuthSession? initialSession}) {
    final session = InMemorySessionStore(initialSession);
    final api = ApiClient.offline(tokenProvider: session.token);
    return AppDependencies(
      api: api,
      session: session,
      discoveryRepository: DiscoveryRepositoryImpl(
        remote: DiscoveryRemoteDataSource(api),
        local: const DiscoveryLocalDataSource(),
        forceLocal: true,
      ),
      escrowRepository: EscrowRepositoryImpl(
        remote: EscrowRemoteDataSource(),
        local: const EscrowLocalDataSource(),
        forceLocal: true,
      ),
      authRepository: DemoAuthRepository(session),
    );
  }

  /// Klien REST bersama. Repository modul lain menerima instance ini, mis.
  /// `OrderRemoteDataSource(api)`.
  final ApiClient api;

  /// Token + pengguna aktif (T-07).
  final SessionStore session;
  final DiscoveryRepository discoveryRepository;
  final EscrowRepository escrowRepository;

  /// Login/registrasi/logout; menyimpan sesi ke [session].
  final AuthRepository authRepository;

  late final StreamSubscription<ApiException> _unauthorizedSub;

  /// Dipanggil sekali sebelum `runApp`: memulihkan sesi tersimpan.
  Future<void> init() async {
    try {
      await session.load();
    } on Object catch (error) {
      // Penyimpanan aman tidak tersedia (mis. keychain terkunci): lanjut
      // sebagai belum login, jangan membuat aplikasi gagal dibuka.
      debugPrint('[Session] gagal memuat sesi: $error');
    }
  }

  /// Bersihkan langganan & koneksi (tes / saat aplikasi ditutup).
  Future<void> dispose() async {
    await _unauthorizedSub.cancel();
    api.close();
  }

  DiscoveryController createDiscoveryController({
    DiscoveryFilter initialFilter = const DiscoveryFilter(),
  }) {
    return DiscoveryController(
      searchNearby: SearchNearbyServices(discoveryRepository),
      getCategories: GetServiceCategories(discoveryRepository),
      initialFilter: initialFilter,
    );
  }
}

/// Menyediakan [AppDependencies] ke seluruh widget tree.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.dependencies, required super.child});

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan di atas widget ini.');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
