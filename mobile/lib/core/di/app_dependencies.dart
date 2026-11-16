import 'package:flutter/material.dart';

import '../../features/discovery/data/datasources/discovery_local_data_source.dart';
import '../../features/discovery/data/datasources/discovery_remote_data_source.dart';
import '../../features/discovery/data/repositories/discovery_repository_impl.dart';
import '../../features/discovery/domain/entities/discovery_filter.dart';
import '../../features/discovery/domain/repositories/discovery_repository.dart';
import '../../features/discovery/domain/usecases/discovery_usecases.dart';
import '../../features/discovery/presentation/controllers/discovery_controller.dart';
import '../../features/escrow/data/datasources/escrow_local_data_source.dart';
import '../../features/escrow/data/datasources/escrow_remote_data_source.dart';
import '../../features/escrow/domain/repositories/escrow_repository_impl.dart';
import '../../features/escrow/domain/repositories/escrow_repository.dart';
import '../config/app_config.dart';

/// Composition root (dependency injection manual, tanpa paket tambahan).
class AppDependencies {
  AppDependencies({
    required this.discoveryRepository,
    required this.escrowRepository,
  });

  factory AppDependencies.production() {
    return AppDependencies(
      discoveryRepository: DiscoveryRepositoryImpl(
        remote: DiscoveryRemoteDataSource(),
        local: const DiscoveryLocalDataSource(),
        forceLocal: AppConfig.useMockData,
      ),
      escrowRepository: EscrowRepositoryImpl(
        remote: EscrowRemoteDataSource(),
        local: const EscrowLocalDataSource(),
        forceLocal: AppConfig.useMockData,
      ),
    );
  }

  /// Dipakai widget test: selalu data lokal, tanpa jaringan.
  factory AppDependencies.offline() {
    return AppDependencies(
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
    );
  }

  final DiscoveryRepository discoveryRepository;
  final EscrowRepository escrowRepository;

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