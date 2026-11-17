import '../../../../core/demo/demo_data.dart';
import '../models/escrow_order_model.dart';
import '../models/escrow_payment_model.dart';

class EscrowLocalDataSource {
  const EscrowLocalDataSource();

  EscrowOrderModel getSampleOrder([String? orderId, String statusKode = 'requested']) {
    const demo = DemoData.order;
    final isProgress = statusKode == 'in_progress';
    final isAccepted = statusKode == 'accepted';
    final statusPesanan = isProgress
        ? 'Dikerjakan'
        : (isAccepted ? 'Disepakati' : 'Diajukan');
    final statusEscrow = isProgress ? 'Ditahan (Simulasi)' : 'Menunggu';

    return EscrowOrderModel(
      orderId: orderId ?? '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
      kodePesanan: demo.code,
      judulLayanan: demo.title,
      statusKode: statusKode,
      statusPesanan: statusPesanan,
      statusEscrow: statusEscrow,
      harga: demo.amount.toInt(),
      stepperTahap: isProgress ? 2 : (isAccepted ? 1 : 0),
      namaLawanTransaksi: demo.provider,
      peranLawanTransaksi: 'Penyedia Jasa',
      tenggat: DateTime.now().add(Duration(days: demo.deadlineDays)),
      detikTersisa: demo.deadlineDays * 86400,
      deskripsiBrief: demo.serviceTitle,
      catatanBrief: 'Output: CMYK 300 DPI (PDF & JPG)',
      tautanBerkas:
          'https://drive.google.com/salma/spanduk-berkah-cibiru-final.pdf',
      catatanPenyedia:
          'Halo Pak Dimas, desain spanduk 3x1 m sudah selesai format CMYK siap cetak.',
      batasRevisi: 2,
      revisiTerpakai: 0,
      sisaRevisi: 2,
    );
  }

  List<EscrowOrderModel> getSampleOrders() => [getSampleOrder()];

  EscrowPaymentModel getSamplePayment([String? orderId, bool isSuccess = true]) {
    return EscrowPaymentModel(
      paymentId: 'pay-sample-001',
      orderId: orderId ?? '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
      nominal: 50000.0,
      statusKode: isSuccess ? 'success' : 'failed',
      statusPembayaran: isSuccess ? 'Berhasil' : 'Gagal',
      referensiSimulasi: 'SIM-DEMO-123456',
      jumlahPercobaan: 1,
      bolehLanjutInProgress: isSuccess,
      disclaimerKeterangan: 'Simulasi pembayaran internal khusus MVP SakuSkill.',
    );
  }
}