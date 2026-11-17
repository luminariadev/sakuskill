class BarterAgreementModel {
  const BarterAgreementModel({
    required this.id,
    required this.listingId,
    this.listingPengajuId,
    required this.pengajuId,
    required this.penerimaId,
    required this.deskripsiJasaPengaju,
    required this.deskripsiJasaPenerima,
    required this.tenggatPekerjaan,
    this.setujuPengaju = false,
    this.setujuPenerima = false,
    this.konfirmasiSelesaiPengaju = false,
    this.konfirmasiSelesaiPenerima = false,
    required this.status,
    required this.statusKode,
    required this.namaPengaju,
    required this.namaPenerima,
  });

  factory BarterAgreementModel.fromJson(Map<String, dynamic> json) {
    return BarterAgreementModel(
      id: (json['barter_id'] ?? json['id'] ?? '').toString(),
      listingId: (json['listing_id'] ?? '').toString(),
      listingPengajuId: json['listing_pengaju_id']?.toString(),
      pengajuId: (json['pengaju_id'] ?? '').toString(),
      penerimaId: (json['penerima_id'] ?? '').toString(),
      deskripsiJasaPengaju: (json['deskripsi_jasa_pengaju'] ?? '').toString(),
      deskripsiJasaPenerima: (json['deskripsi_jasa_penerima'] ?? '').toString(),
      tenggatPekerjaan: json['tenggat_pekerjaan'] != null
          ? DateTime.tryParse(json['tenggat_pekerjaan'].toString()) ?? DateTime.now()
          : DateTime.now(),
      setujuPengaju: json['setuju_pengaju'] == true,
      setujuPenerima: json['setuju_penerima'] == true,
      konfirmasiSelesaiPengaju: json['konfirmasi_selesai_pengaju'] == true,
      konfirmasiSelesaiPenerima: json['konfirmasi_selesai_penerima'] == true,
      status: (json['status'] ?? 'Diajukan').toString(),
      statusKode: (json['status_kode'] ?? 'requested').toString(),
      namaPengaju: (json['nama_pengaju'] ?? '').toString(),
      namaPenerima: (json['nama_penerima'] ?? '').toString(),
    );
  }

  final String id;
  final String listingId;
  final String? listingPengajuId;
  final String pengajuId;
  final String penerimaId;
  final String deskripsiJasaPengaju;
  final String deskripsiJasaPenerima;
  final DateTime tenggatPekerjaan;
  final bool setujuPengaju;
  final bool setujuPenerima;
  final bool konfirmasiSelesaiPengaju;
  final bool konfirmasiSelesaiPenerima;
  final String status;
  final String statusKode;
  final String namaPengaju;
  final String namaPenerima;

  bool get isCompleted => statusKode == 'completed' || status == 'Selesai';
  bool get isInProgress => statusKode == 'in_progress' || status == 'Dikerjakan';
  bool get isWaitingConfirmation =>
      statusKode == 'completion_requested' || status == 'Menunggu Konfirmasi';
}
