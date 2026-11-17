class EscrowPaymentModel {
  const EscrowPaymentModel({
    required this.paymentId,
    required this.orderId,
    required this.nominal,
    required this.statusKode,
    required this.statusPembayaran,
    required this.referensiSimulasi,
    required this.jumlahPercobaan,
    required this.bolehLanjutInProgress,
    required this.disclaimerKeterangan,
  });

  final String paymentId;
  final String orderId;
  final double nominal;
  final String statusKode; // pending | success | failed
  final String statusPembayaran;
  final String referensiSimulasi;
  final int jumlahPercobaan;
  final bool bolehLanjutInProgress;
  final String disclaimerKeterangan;

  factory EscrowPaymentModel.fromJson(Map<String, dynamic> json) {
    // Parser nominal aman untuk string angka desimal dari backend PostgreSQL
    double parseNominal(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final relasi = json['relasi_order'] as Map<String, dynamic>?;
    final disclaimer = json['disclaimer_mvp'] as Map<String, dynamic>?;

    return EscrowPaymentModel(
      paymentId: json['payment_id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      nominal: parseNominal(json['nominal']),
      statusKode: json['status_kode']?.toString() ?? 'pending',
      statusPembayaran: json['status_pembayaran']?.toString() ?? 'Menunggu',
      referensiSimulasi: json['referensi_simulasi']?.toString() ?? '',
      jumlahPercobaan: (json['jumlah_percobaan'] as num?)?.toInt() ?? 1,
      bolehLanjutInProgress: (relasi?['boleh_lanjut_in_progress'] as bool?) ?? 
          (json['status_kode'] == 'success'),
      disclaimerKeterangan: disclaimer?['keterangan']?.toString() ?? 
          'Simulasi pembayaran internal khusus MVP SakuSkill.',
    );
  }
}