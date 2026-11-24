import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/auth_session.dart';
import '../../features/barter/data/datasources/barter_remote_data_source.dart';
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
import '../storage/session_store.dart' as secure;

/// Composition root (dependency injection manual, tanpa paket tambahan).
class AppDependencies {
  AppDependencies({
    required this.session,
    required this.api,
    required this.authRepository,
    required this.discoveryRepository,
    required this.escrowRepository,
    required this.barterDataSource,
  }) {
    _unauthSub = api.unauthorizedEvents.listen(
      (_) => AuthSession.instance.notifyUnauthorized(),
    );
  }

  factory AppDependencies.production({secure.SessionStore? sessionStore}) {
    final store = sessionStore ?? secure.SecureSessionStore();
    if (!AppConfig.useMockData) {
      AuthSession.instance.bind(store);
    }
    final api = ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: () => AuthSession.instance.accessToken ?? store.token(),
    );
    final authRepo = AppConfig.useMockData
        ? DemoAuthRepository(store)
        : ApiAuthRepository(api, store);
    return AppDependencies(
      session: store,
      api: api,
      authRepository: authRepo,
      discoveryRepository: DiscoveryRepositoryImpl(
        remote: DiscoveryRemoteDataSource(),
        local: const DiscoveryLocalDataSource(),
        forceLocal: AppConfig.useMockData,
      ),
      escrowRepository: EscrowRepositoryImpl(
        remote: EscrowRemoteDataSource(
          tokenProvider: () async => AuthSession.instance.accessToken,
          onUnauthorized: AuthSession.instance.notifyUnauthorized,
        ),
        local: const EscrowLocalDataSource(),
        forceLocal: AppConfig.useMockData,
      ),
      barterDataSource: BarterRemoteDataSource(
        tokenProvider: () async => AuthSession.instance.accessToken,
        onUnauthorized: AuthSession.instance.notifyUnauthorized,
      ),
    );
  }

  /// Dipakai widget test: selalu data lokal, tanpa jaringan.
  factory AppDependencies.offline({
    secure.AuthSession? initialSession,
    AuthRepository? authRepository,
    BarterRemoteDataSource? barterDataSource,
  }) {
    final store = secure.InMemorySessionStore(initialSession);
    final api = ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: store.token,
      releaseMode: false,
    );
    return AppDependencies(
      session: store,
      api: api,
      authRepository: authRepository ?? DemoAuthRepository(store),
      discoveryRepository: DiscoveryRepositoryImpl(
        remote: DiscoveryRemoteDataSource(),
        local: const DiscoveryLocalDataSource(),
        forceLocal: true,
      ),
      escrowRepository: EscrowRepositoryImpl(
        remote: EscrowRemoteDataSource(),
        local: const EscrowLocalDataSource(),
        forceLocal: true,
      ),
      barterDataSource: barterDataSource ?? BarterRemoteDataSource(),
    );
  }

  final secure.SessionStore session;
  final ApiClient api;
  final AuthRepository authRepository;
  final DiscoveryRepository discoveryRepository;
  final EscrowRepository escrowRepository;
  final BarterRemoteDataSource barterDataSource;
  StreamSubscription<ApiException>? _unauthSub;

  Future<void> dispose() async {
    await _unauthSub?.cancel();
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