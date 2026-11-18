import 'dart:async';

import '../../data/models/escrow_order_model.dart';
import '../../data/models/escrow_payment_model.dart';

typedef ChatMessageMap = Map<String, dynamic>;
typedef ChatMessageList = List<ChatMessageMap>;

class EscrowActionResult<T> {
  const EscrowActionResult({required this.data, this.isFallback = false});

  final T data;
  final bool isFallback;
}

abstract class EscrowRepository {
  Future<EscrowActionResult<List<EscrowOrderModel>>> fetchMyOrders({
    String peran = 'pelanggan',
    String? status,
  });

  Future<EscrowActionResult<EscrowOrderModel>> fetchOrderDetail(String orderId);

  Future<EscrowActionResult<ChatMessageList>> fetchOrderMessages(
    String orderId,
  );

  Future<EscrowActionResult<ChatMessageMap>> sendOrderMessage({
    required String orderId,
    required String isiPesan,
  });

  Future<EscrowActionResult<EscrowOrderModel>> createOrder({
    required String listingId,
    required String deskripsiKebutuhan,
    required int hargaDisepakati,
    required int durasiHari,
    String? catatanKlien,
  });

  Future<EscrowActionResult<EscrowOrderModel>> submitProposal({
    required String orderId,
    required String deskripsiRuangLingkup,
    required int hargaTawaran,
    DateTime? tenggatUsulan,
  });

  Future<EscrowActionResult<EscrowPaymentModel>> startPayment(String orderId);

  Future<EscrowActionResult<EscrowPaymentModel>> simulatePayment(
    String orderId, {
    required bool berhasil,
    String? alasanGagal,
  });

  Future<EscrowActionResult<EscrowPaymentModel>> fetchPayment(String orderId);

  Future<EscrowActionResult<void>> confirmCompletion(String orderId);

  Future<EscrowActionResult<void>> submitReview({
    required String orderId,
    required int rating,
    String? komentar,
  });

  Future<EscrowActionResult<void>> cancelOrder(
    String orderId, {
    String? alasan,
  });

  Future<EscrowActionResult<EscrowOrderModel>> acceptOrder(String orderId);

  Future<EscrowActionResult<EscrowOrderModel>> rejectOrder(
    String orderId, {
    String? alasan,
  });

  Future<EscrowActionResult<EscrowOrderModel>> startWork(String orderId);

  Future<EscrowActionResult<void>> requestCompletion({
    required String orderId,
    required String tautanBerkas,
    required String catatanPenyedia,
  });

  Future<EscrowActionResult<void>> requestRevision({
    required String orderId,
    required String catatanRevisi,
  });

  Future<EscrowActionResult<EscrowOrderModel>> requestTimeExtension({
    required String orderId,
    required int tambahanJam,
    required String alasan,
    int progresPersen = 75,
  });

  Future<EscrowActionResult<EscrowOrderModel>> decideTimeExtension({
    required String orderId,
    required bool disetujui,
  });

  Future<EscrowActionResult<void>> cancelOverdueOrder(String orderId);

  Future<EscrowActionResult<void>> submitAppeal({
    required String orderId,
    required String alasan,
    required int progresPersen,
    String? tautanBukti,
  });
}
