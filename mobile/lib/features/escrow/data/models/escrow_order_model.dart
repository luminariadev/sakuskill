class EscrowOrderModel {
  const EscrowOrderModel({
    required this.orderId,
    required this.kodePesanan,
    required this.judulLayanan,
    required this.statusPesanan,
    required this.statusEscrow,
    required this.harga,
    required this.stepperTahap,
    this.statusKode = 'requested',
    this.paymentStatusKode,
    this.bolehLanjutInProgress = false,
    this.sudahDiulas = false,
    this.listingId,
    this.pelangganId,
    this.penyediaId,
    this.labelStepper,
    this.namaLawanTransaksi,
    this.peranLawanTransaksi,
    this.tenggat,
    this.detikTersisa,
    this.terlambatDetik = 0,
    this.isTerlambat = false,
    this.deskripsiBrief,
    this.catatanBrief,
    this.lampiranKlien,
    this.tautanBerkas,
    this.catatanPenyedia,
    this.mockupUrl,
    this.batasRevisi = 2,
    this.revisiTerpakai = 0,
    this.sisaRevisi = 2,
  });

  final String orderId;
  final String kodePesanan;
  final String judulLayanan;
  final String statusPesanan;
  final String statusEscrow;
  final int harga;
  final int stepperTahap;
  final String statusKode;

  // Status Pembayaran Terpisah (Kontrak API v1.3)
  final String? paymentStatusKode; // pending | failed | success | null
  final bool bolehLanjutInProgress;
  final bool sudahDiulas;

  final String? listingId;
  final String? pelangganId;
  final String? penyediaId;
  final String? labelStepper;
  final String? namaLawanTransaksi;
  final String? peranLawanTransaksi;
  final DateTime? tenggat;
  final int? detikTersisa;
  final int terlambatDetik;
  final bool isTerlambat;

  // Detail Brief & Kesepakatan
  final String? deskripsiBrief;
  final String? catatanBrief;
  final String? lampiranKlien;

  // Deliverable
  final String? tautanBerkas;
  final String? catatanPenyedia;
  final String? mockupUrl;

  // Kuota Revisi
  final int batasRevisi;
  final int revisiTerpakai;
  final int sisaRevisi;

  /// Helper untuk menentukan peran pengguna saat ini pada transaksi ini.
  bool adalahPelanggan(String currentUserId) =>
      pelangganId != null && pelangganId == currentUserId;

  bool adalahPenyedia(String currentUserId) =>
      penyediaId != null && penyediaId == currentUserId;

  static int _parseMoney(dynamic raw) {
    if (raw is num) return raw.round();
    if (raw is String) {
      final parsed = double.tryParse(raw.trim());
      if (parsed != null) return parsed.round();
    }
    return 0;
  }

  static int _mapStepperTahap(String statusKode, dynamic rawTahap) {
    if (rawTahap is num) return rawTahap.toInt();
    switch (statusKode) {
      case 'requested':
      case 'negotiating':
        return 1;
      case 'accepted':
      case 'in_progress':
        return 2;
      case 'completion_requested':
        return 3;
      case 'completed':
      case 'rejected':
      case 'cancelled':
        return 4;
      default:
        return 1;
    }
  }

  static String _mapStatusEscrow(
    String statusKode,
    String? paymentKode,
    String? explicitEscrow,
  ) {
    if (explicitEscrow != null && explicitEscrow.isNotEmpty) {
      return explicitEscrow;
    }
    if (statusKode == 'completed') {
      return 'Dana Dilepas ke Penyedia (Simulasi)';
    }
    if (statusKode == 'rejected' || statusKode == 'cancelled') {
      return paymentKode == 'success'
          ? 'Dana Dikembalikan (Simulasi)'
          : 'Tidak Ada Dana Ditahan';
    }
    switch (paymentKode) {
      case 'success':
        return 'Dana Ditahan (Simulasi)';
      case 'pending':
        return 'Menunggu Pembayaran (Simulasi)';
      case 'failed':
        return 'Pembayaran Gagal (Simulasi)';
      default:
        return statusKode == 'accepted'
            ? 'Belum Dibayar'
            : 'Menunggu Kesepakatan';
    }
  }

  factory EscrowOrderModel.fromJson(Map<String, dynamic> json) {
    final snapshotGig = json['snapshot_gig'] as Map<String, dynamic>?;
    final kesepakatan = json['kesepakatan'] as Map<String, dynamic>?;
    final lawan = json['lawan_transaksi'] as Map<String, dynamic>?;
    final payment =
        (json['payment'] ?? json['pembayaran']) as Map<String, dynamic>?;
    final relasiOrder = payment?['relasi_order'] as Map<String, dynamic>?;
    final reviews = json['reviews'] as List<dynamic>?;
    final brief = json['brief'] as Map<String, dynamic>?;
    final sla = json['sla'] as Map<String, dynamic>?;
    final deliverable = json['deliverable'] as Map<String, dynamic>?;
    final revisi = json['revisi'] as Map<String, dynamic>?;

    final orderId = (json['order_id'] ?? '') as String;
    final statusKode = (json['status_kode'] ?? 'requested') as String;
    final paymentKode = payment?['status_kode'] as String?;

    final rawTenggat = (kesepakatan?['deadline'] ??
        json['tenggat_pekerjaan'] ??
        sla?['tenggat'] ??
        json['tenggat']) as String?;
    final parsedTenggat =
        rawTenggat != null ? DateTime.tryParse(rawTenggat) : null;

    final now = DateTime.now();
    final isTerminal = const {
      'completed',
      'rejected',
      'cancelled',
    }.contains(statusKode);

    final computedLate = (sla?['is_terlambat'] as bool?) ??
        (parsedTenggat != null && !isTerminal && parsedTenggat.isBefore(now));
    final computedRemaining = (sla?['detik_tersisa'] as num?)?.toInt() ??
        (parsedTenggat != null
            ? parsedTenggat.difference(now).inSeconds.clamp(0, 31536000)
            : null);
    final computedLateSeconds =
        (parsedTenggat != null && !isTerminal && parsedTenggat.isBefore(now))
            ? now.difference(parsedTenggat).inSeconds
            : 0;

    final shortCode = orderId.length >= 8
        ? 'ORD-${orderId.substring(0, 8).toUpperCase()}'
        : orderId;

    final scopeText = (kesepakatan?['scope'] ??
        json['ruang_lingkup'] ??
        json['catatan_kebutuhan'] ??
        brief?['deskripsi']) as String?;

    final maxRev = ((revisi?['batas_maksimal'] ?? 2) as num).toInt();
    final usedRev = ((revisi?['telah_digunakan'] ?? 0) as num).toInt();
    final remRev = ((revisi?['sisa_kesempatan'] ?? (maxRev - usedRev)) as num)
        .toInt()
        .clamp(0, maxRev);

    return EscrowOrderModel(
      orderId: orderId,
      kodePesanan: (json['kode_pesanan'] ?? shortCode) as String,
      judulLayanan: (snapshotGig?['judul'] ??
              json['snapshot_judul'] ??
              json['judul_layanan'] ??
              scopeText ??
              'Pesanan Layanan') as String,
      statusPesanan: (json['status_pesanan'] ?? 'Diajukan') as String,
      statusEscrow: _mapStatusEscrow(
        statusKode,
        paymentKode,
        (json['status_escrow'] ?? payment?['status_dana_simulasi']) as String?,
      ),
      harga: _parseMoney(
        kesepakatan?['harga_final'] ??
            json['harga_kesepakatan'] ??
            snapshotGig?['harga_awal'] ??
            json['snapshot_harga'] ??
            json['harga'] ??
            json['harga_disepakati'],
      ),
      stepperTahap: _mapStepperTahap(statusKode, json['stepper_tahap']),
      statusKode: statusKode,
      paymentStatusKode: paymentKode,
      bolehLanjutInProgress:
          (relasiOrder?['boleh_lanjut_in_progress'] as bool?) ??
              (paymentKode == 'success'),
      sudahDiulas: reviews?.isNotEmpty ?? false,
      listingId: (json['gig_id'] ?? json['listing_id']) as String?,
      pelangganId: json['pelanggan_id'] as String?,
      penyediaId: json['penyedia_id'] as String?,
      labelStepper:
          (json['label_stepper'] ?? json['status_pesanan']) as String?,
      namaLawanTransaksi: (lawan?['nama'] ??
          json['nama_penyedia'] ??
          json['nama_pelanggan']) as String?,
      peranLawanTransaksi: (lawan?['peran'] ??
          (json['nama_penyedia'] != null ? 'Penyedia Jasa' : null)) as String?,
      tenggat: parsedTenggat,
      detikTersisa: computedRemaining,
      terlambatDetik: computedLateSeconds,
      isTerlambat: computedLate,
      deskripsiBrief: scopeText,
      catatanBrief: (json['catatan_kebutuhan'] ??
          snapshotGig?['ketentuan'] ??
          json['snapshot_ketentuan'] ??
          brief?['catatan']) as String?,
      lampiranKlien: brief?['lampiran_klien'] as String?,
      tautanBerkas: deliverable?['tautan_berkas'] as String?,
      catatanPenyedia: deliverable?['catatan_penyedia'] as String?,
      mockupUrl: deliverable?['mockup_url'] as String?,
      batasRevisi: maxRev,
      revisiTerpakai: usedRev,
      sisaRevisi: remRev,
    );
  }

  EscrowOrderModel copyWith({
    String? orderId,
    String? kodePesanan,
    String? judulLayanan,
    String? statusPesanan,
    String? statusEscrow,
    int? harga,
    int? stepperTahap,
    String? statusKode,
    String? paymentStatusKode,
    bool? bolehLanjutInProgress,
    bool? sudahDiulas,
    String? listingId,
    String? pelangganId,
    String? penyediaId,
    String? labelStepper,
    String? namaLawanTransaksi,
    String? peranLawanTransaksi,
    DateTime? tenggat,
    int? detikTersisa,
    int? terlambatDetik,
    bool? isTerlambat,
    String? deskripsiBrief,
    String? catatanBrief,
    String? lampiranKlien,
    String? tautanBerkas,
    String? catatanPenyedia,
    String? mockupUrl,
    int? batasRevisi,
    int? revisiTerpakai,
    int? sisaRevisi,
  }) {
    return EscrowOrderModel(
      orderId: orderId ?? this.orderId,
      kodePesanan: kodePesanan ?? this.kodePesanan,
      judulLayanan: judulLayanan ?? this.judulLayanan,
      statusPesanan: statusPesanan ?? this.statusPesanan,
      statusEscrow: statusEscrow ?? this.statusEscrow,
      harga: harga ?? this.harga,
      stepperTahap: stepperTahap ?? this.stepperTahap,
      statusKode: statusKode ?? this.statusKode,
      paymentStatusKode: paymentStatusKode ?? this.paymentStatusKode,
      bolehLanjutInProgress:
          bolehLanjutInProgress ?? this.bolehLanjutInProgress,
      sudahDiulas: sudahDiulas ?? this.sudahDiulas,
      listingId: listingId ?? this.listingId,
      pelangganId: pelangganId ?? this.pelangganId,
      penyediaId: penyediaId ?? this.penyediaId,
      labelStepper: labelStepper ?? this.labelStepper,
      namaLawanTransaksi: namaLawanTransaksi ?? this.namaLawanTransaksi,
      peranLawanTransaksi: peranLawanTransaksi ?? this.peranLawanTransaksi,
      tenggat: tenggat ?? this.tenggat,
      detikTersisa: detikTersisa ?? this.detikTersisa,
      terlambatDetik: terlambatDetik ?? this.terlambatDetik,
      isTerlambat: isTerlambat ?? this.isTerlambat,
      deskripsiBrief: deskripsiBrief ?? this.deskripsiBrief,
      catatanBrief: catatanBrief ?? this.catatanBrief,
      lampiranKlien: lampiranKlien ?? this.lampiranKlien,
      tautanBerkas: tautanBerkas ?? this.tautanBerkas,
      catatanPenyedia: catatanPenyedia ?? this.catatanPenyedia,
      mockupUrl: mockupUrl ?? this.mockupUrl,
      batasRevisi: batasRevisi ?? this.batasRevisi,
      revisiTerpakai: revisiTerpakai ?? this.revisiTerpakai,
      sisaRevisi: sisaRevisi ?? this.sisaRevisi,
    );
  }
}