import '../../data/models/escrow_order_model.dart';

class EscrowActionResult<T> {
  const EscrowActionResult({required this.data, this.isFallback = false});

  final T data;
  final bool isFallback;
}

abstract class EscrowRepository {
  Future<EscrowActionResult<EscrowOrderModel>> createOrder({
    required String listingId,
    required String deskripsiKebutuhan,
    required int hargaDisepakati,
    required int durasiHari,
    String? catatanKlien,
  });

  Future<EscrowActionResult<List<EscrowOrderModel>>> fetchMyOrders({
    String peran = 'pembeli',
    String? status,
  });

  Future<EscrowActionResult<EscrowOrderModel>> fetchOrderDetail(String orderId);

  Future<EscrowActionResult<void>> deliverWork({
    required String orderId,
    required String tautanBerkas,
    required String catatanPenyedia,
    String? mockupUrl,
    bool konfirmasiKesesuaianBrief = true,
  });

  Future<EscrowActionResult<void>> releaseFund(String orderId, {int? rating});

  Future<EscrowActionResult<void>> requestRevision({
    required String orderId,
    required String catatanRevisi,
  });

  Future<EscrowActionResult<void>> requestTimeExtension({
    required String orderId,
    required int tambahanJam,
    required String alasan,
    required int progresPersen,
  });

  Future<EscrowActionResult<void>> decideTimeExtension({
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
