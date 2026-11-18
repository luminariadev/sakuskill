import 'dart:async';

import 'package:flutter/foundation.dart';

import 'escrow_repository.dart';
import '../../data/datasources/escrow_local_data_source.dart';
import '../../data/datasources/escrow_remote_data_source.dart';
import '../../data/models/escrow_order_model.dart';
import '../../data/models/escrow_payment_model.dart';

class EscrowRepositoryImpl implements EscrowRepository {
  EscrowRepositoryImpl({
    required EscrowRemoteDataSource remote,
    required EscrowLocalDataSource local,
    this.forceLocal = false,
  })  : _remote = remote,
        _local = local;

  final EscrowRemoteDataSource _remote;
  final EscrowLocalDataSource _local;
  final bool forceLocal;

  Future<EscrowActionResult<T>> _runWithFallback<T>({
    required Future<T> Function() remoteCall,
    required T Function() fallbackCall,
    required String actionName,
    bool isWrite = false,
  }) async {
    if (forceLocal) {
      return EscrowActionResult(data: fallbackCall(), isFallback: true);
    }
    try {
      final result = await remoteCall();
      return EscrowActionResult(data: result, isFallback: false);
    } on EscrowException {
      rethrow;
    } catch (error) {
      if (isWrite) {
        throw const EscrowException(
          'Server tidak terjangkau. Periksa koneksi internet atau server lokal Anda.',
          code: 'NETWORK_ERROR',
        );
      }
      debugPrint(
        '[Escrow][$actionName] API tidak terjangkau, pakai data contoh: $error',
      );
      return EscrowActionResult(data: fallbackCall(), isFallback: true);
    }
  }

  @override
  Future<EscrowActionResult<List<EscrowOrderModel>>> fetchMyOrders({
    String peran = 'pelanggan',
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
  Future<EscrowActionResult<ChatMessageList>> fetchOrderMessages(
    String orderId,
  ) {
    return _runWithFallback(
      actionName: 'fetchOrderMessages',
      remoteCall: () => _remote.fetchOrderMessages(orderId),
      fallbackCall: () => const [],
    );
  }

  @override
  Future<EscrowActionResult<ChatMessageMap>> sendOrderMessage({
    required String orderId,
    required String isiPesan,
  }) {
    return _runWithFallback(
      actionName: 'sendOrderMessage',
      isWrite: true,
      remoteCall: () => _remote.sendOrderMessage(
        orderId: orderId,
        isiPesan: isiPesan,
      ),
      fallbackCall: () => {
        'message_id': 'local-${DateTime.now().millisecondsSinceEpoch}',
        'order_id': orderId,
        'sender_id': '',
        'isi_pesan': isiPesan.trim(),
        'dibuat_pada': DateTime.now().toUtc().toIso8601String(),
      },
    );
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
      isWrite: true,
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
  Future<EscrowActionResult<EscrowOrderModel>> submitProposal({
    required String orderId,
    required String deskripsiRuangLingkup,
    required int hargaTawaran,
    DateTime? tenggatUsulan,
  }) {
    return _runWithFallback(
      actionName: 'submitProposal',
      isWrite: true,
      remoteCall: () => _remote.submitProposal(
        orderId: orderId,
        deskripsiRuangLingkup: deskripsiRuangLingkup,
        hargaTawaran: hargaTawaran,
        tenggatUsulan: tenggatUsulan,
      ),
      fallbackCall: () => _local.getSampleOrder(orderId),
    );
  }

  @override
  Future<EscrowActionResult<EscrowPaymentModel>> startPayment(String orderId) {
    return _runWithFallback(
      actionName: 'startPayment',
      isWrite: true,
      remoteCall: () async {
        final json = await _remote.createPayment(orderId);
        return EscrowPaymentModel.fromJson(json);
      },
      fallbackCall: () => throw const EscrowException(
        'Simulasi pembayaran membutuhkan koneksi ke backend.',
      ),
    );
  }

  @override
  Future<EscrowActionResult<EscrowPaymentModel>> simulatePayment(
    String orderId, {
    required bool berhasil,
    String? alasanGagal,
  }) {
    return _runWithFallback(
      actionName: 'simulatePayment',
      isWrite: true,
      remoteCall: () async {
        final json = berhasil
            ? await _remote.simulatePaymentSuccess(orderId)
            : await _remote.simulatePaymentFailed(orderId, alasan: alasanGagal);
        return EscrowPaymentModel.fromJson(json);
      },
      fallbackCall: () => throw const EscrowException(
        'Simulasi pembayaran membutuhkan koneksi ke backend.',
      ),
    );
  }

  @override
  Future<EscrowActionResult<EscrowPaymentModel>> fetchPayment(String orderId) {
    return _runWithFallback(
      actionName: 'fetchPayment',
      isWrite: false,
      remoteCall: () async {
        final json = await _remote.fetchPayment(orderId);
        return EscrowPaymentModel.fromJson(json);
      },
      fallbackCall: () => throw const EscrowException(
        'Data pembayaran tidak tersedia di mode offline.',
      ),
    );
  }

  @override
  Future<EscrowActionResult<void>> confirmCompletion(String orderId) {
    return _runWithFallback(
      actionName: 'confirmCompletion',
      isWrite: true,
      remoteCall: () => _remote.releaseFund(orderId),
      fallbackCall: () {},
    );
  }

  @override
  Future<EscrowActionResult<void>> submitReview({
    required String orderId,
    required int rating,
    String? komentar,
  }) {
    return _runWithFallback(
      actionName: 'submitReview',
      isWrite: true,
      remoteCall: () => _remote.submitReview(
        orderId: orderId,
        rating: rating,
        komentar: komentar,
      ),
      fallbackCall: () {},
    );
  }

  @override
  Future<EscrowActionResult<void>> cancelOrder(
    String orderId, {
    String? alasan,
  }) {
    return _runWithFallback(
      actionName: 'cancelOrder',
      isWrite: true,
      remoteCall: () => _remote.cancelOverdueOrder(
        orderId,
        alasan: alasan ?? 'Pesanan dibatalkan oleh pelanggan.',
      ),
      fallbackCall: () {},
    );
  }

  @override
  Future<EscrowActionResult<EscrowOrderModel>> acceptOrder(String orderId) {
    return _runWithFallback(
      actionName: 'acceptOrder',
      isWrite: true,
      remoteCall: () => _remote.acceptOrder(orderId),
      fallbackCall: () => _local.getSampleOrder(orderId),
    );
  }

  @override
  Future<EscrowActionResult<EscrowOrderModel>> rejectOrder(
    String orderId, {
    String? alasan,
  }) {
    return _runWithFallback(
      actionName: 'rejectOrder',
      isWrite: true,
      remoteCall: () => _remote.rejectOrder(orderId, alasan: alasan),
      fallbackCall: () => _local.getSampleOrder(orderId),
    );
  }

  @override
  Future<EscrowActionResult<EscrowOrderModel>> startWork(String orderId) {
    return _runWithFallback(
      actionName: 'startWork',
      isWrite: true,
      remoteCall: () => _remote.startWorkOrder(orderId),
      fallbackCall: () => _local.getSampleOrder(orderId),
    );
  }

  @override
  Future<EscrowActionResult<void>> requestCompletion({
    required String orderId,
    required String tautanBerkas,
    required String catatanPenyedia,
  }) {
    return _runWithFallback(
      actionName: 'requestCompletion',
      isWrite: true,
      remoteCall: () => _remote.deliverWork(
        orderId: orderId,
        tautanBerkas: tautanBerkas,
        catatanPenyedia: catatanPenyedia,
      ),
      fallbackCall: () {},
    );
  }

  @override
  Future<EscrowActionResult<void>> requestRevision({
    required String orderId,
    required String catatanRevisi,
  }) async {
    return const EscrowActionResult<void>(data: null, isFallback: true);
  }

  @override
  Future<EscrowActionResult<EscrowOrderModel>> requestTimeExtension({
    required String orderId,
    required int tambahanJam,
    required String alasan,
    int progresPersen = 75,
  }) {
    return _runWithFallback(
      actionName: 'requestTimeExtension',
      isWrite: true,
      remoteCall: () => _remote.requestTimeExtension(
        orderId: orderId,
        tambahanJam: tambahanJam,
        alasan: alasan,
        progresPersen: progresPersen,
      ),
      fallbackCall: () => _local.getSampleOrder(orderId),
    );
  }

  @override
  Future<EscrowActionResult<EscrowOrderModel>> decideTimeExtension({
    required String orderId,
    required bool disetujui,
  }) {
    return _runWithFallback(
      actionName: 'decideTimeExtension',
      isWrite: true,
      remoteCall: () => _remote.decideTimeExtension(
        orderId: orderId,
        disetujui: disetujui,
      ),
      fallbackCall: () => _local.getSampleOrder(orderId),
    );
  }

  @override
  Future<EscrowActionResult<void>> cancelOverdueOrder(String orderId) {
    return _runWithFallback(
      actionName: 'cancelOverdueOrder',
      isWrite: true,
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
      isWrite: true,
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