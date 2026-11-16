import '../../../../core/demo/demo_data.dart';
import '../models/escrow_order_model.dart';

class EscrowLocalDataSource {
  const EscrowLocalDataSource();

  EscrowOrderModel getSampleOrder([String? orderId]) {
    const demo = DemoData.order;
    return EscrowOrderModel(
      orderId: orderId ?? '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
      kodePesanan: demo.code,
      judulLayanan: demo.title,
      statusPesanan: 'Dikerjakan',
      statusEscrow: 'Ditahan (Simulasi)',
      harga: demo.amount.toInt(),
      stepperTahap: 2,
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
}