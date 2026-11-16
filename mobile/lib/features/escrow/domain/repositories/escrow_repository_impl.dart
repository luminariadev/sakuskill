import 'package:flutter/foundation.dart';

import '../../domain/repositories/escrow_repository.dart';
import '../../data/datasources/escrow_local_data_source.dart';
import '../../data/datasources/escrow_remote_data_source.dart';
import '../../data/models/escrow_order_model.dart';

class EscrowRepositoryImpl implements EscrowRepository {
  EscrowRepositoryImpl({
    required this._remote,
    required this._local,
    this.forceLocal = false,
  });

  final EscrowRemoteDataSource _remote;
  final EscrowLocalDataSource _local;
  final bool forceLocal;

  Future<EscrowActionResult<T>> _runWithFallback<T>({
    required Future<T> Function() remoteCall,
    required T Function() fallbackCall,
    required String actionName,
  }) async {
    if (forceLocal) {
      return EscrowActionResult(data: fallbackCall(), isFallback: false);
    }
    try {
      final result = await remoteCall();
      return EscrowActionResult(data: result, isFallback: false);
    } catch (error) {
      debugPrint(
        '[Escrow][$actionName] API tidak terjangkau, pakai data contoh: $error',
      );
      return EscrowActionResult(data: fallbackCall(), isFallback: true);
    }
  }

  @override
  Future<EscrowActionResult<EscrowOrderModel>> createOrder({
    required String listingId,
    required String deskripsiKebutuhan,
    required int hargaDisepakati,
    required int durasiHari,
    String? catatanKlien,
  }) {
    return _runWithFallback(
      actionName: 'createOrder',
      remoteCall: () => _remote.createOrder(
        listingId: listingId,
        deskripsiKebutuhan: deskripsiKebutuhan,
        hargaDisepakati: hargaDisepakati,
        durasiHari: durasiHari,
        catatanKlien: catatanKlien,
      ),
      fallbackCall: () => _local.getSampleOrder(),
    );
  }

  @override
  Future<EscrowActionResult<List<EscrowOrderModel>>> fetchMyOrders({
    String peran = 'pembeli',
    String? status,
  }) {
    return _runWithFallback(
      actionName: 'fetchMyOrders',
      remoteCall: () => _remote.fetchMyOrders(peran: peran, status: status),
      fallbackCall: () => _local.getSampleOrders(),
    );
  }

  @override
  Future<EscrowActionResult<EscrowOrderModel>> fetchOrderDetail(
    String orderId,
  ) {
    return _runWithFallback(
      actionName: 'fetchOrderDetail',
      remoteCall: () => _remote.fetchOrderDetail(orderId),
      fallbackCall: () => _local.getSampleOrder(orderId),
    );
  }

  @override
  Future<EscrowActionResult<void>> deliverWork({
    required String orderId,
    required String tautanBerkas,
    required String catatanPenyedia,
    String? mockupUrl,
    bool konfirmasiKesesuaianBrief = true,
  }) {
    return _runWithFallback(
      actionName: 'deliverWork',
      remoteCall: () => _remote.deliverWork(
        orderId: orderId,
        tautanBerkas: tautanBerkas,
        catatanPenyedia: catatanPenyedia,
        mockupUrl: mockupUrl,
        konfirmasiKesesuaianBrief: konfirmasiKesesuaianBrief,
      ),
      fallbackCall: () {},
    );
  }

  @override
  Future<EscrowActionResult<void>> releaseFund(String orderId, {int? rating}) {
    return _runWithFallback(
      actionName: 'releaseFund',
      remoteCall: () => _remote.releaseFund(orderId, rating: rating),
      fallbackCall: () {},
    );
  }

  @override
  Future<EscrowActionResult<void>> requestRevision({
    required String orderId,
    required String catatanRevisi,
  }) {
    return _runWithFallback(
      actionName: 'requestRevision',
      remoteCall: () => _remote.requestRevision(
        orderId: orderId,
        catatanRevisi: catatanRevisi,
      ),
      fallbackCall: () {},
    );
  }

  @override
  Future<EscrowActionResult<void>> requestTimeExtension({
    required String orderId,
    required int tambahanJam,
    required String alasan,
    required int progresPersen,
  }) {
    return _runWithFallback(
      actionName: 'requestTimeExtension',
      remoteCall: () => _remote.requestTimeExtension(
        orderId: orderId,
        tambahanJam: tambahanJam,
        alasan: alasan,
        progresPersen: progresPersen,
      ),
      fallbackCall: () {},
    );
  }

  @override
  Future<EscrowActionResult<void>> decideTimeExtension({
    required String orderId,
    required bool disetujui,
  }) {
    return _runWithFallback(
      actionName: 'decideTimeExtension',
      remoteCall: () =>
          _remote.decideTimeExtension(orderId: orderId, disetujui: disetujui),
      fallbackCall: () {},
    );
  }

  @override
  Future<EscrowActionResult<void>> cancelOverdueOrder(String orderId) {
    return _runWithFallback(
      actionName: 'cancelOverdueOrder',
      remoteCall: () => _remote.cancelOverdueOrder(orderId),
      fallbackCall: () {},
    );
  }

  @override
  Future<EscrowActionResult<void>> submitAppeal({
    required String orderId,
    required String alasan,
    required int progresPersen,
    String? tautanBukti,
  }) {
    return _runWithFallback(
      actionName: 'submitAppeal',
      remoteCall: () => _remote.submitAppeal(
        orderId: orderId,
        alasan: alasan,
        progresPersen: progresPersen,
        tautanBukti: tautanBukti,
      ),
      fallbackCall: () {},
    );
  }
}
