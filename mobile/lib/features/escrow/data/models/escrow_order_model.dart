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
    this.listingId,
    this.pelangganId,
    this.penyediaId,
    this.labelStepper,
    this.namaLawanTransaksi,
    this.peranLawanTransaksi,
    this.tenggat,
    this.detikTersisa,
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
  final String? listingId;
  final String? pelangganId;
  final String? penyediaId;
  final String? labelStepper;
  final String? namaLawanTransaksi;
  final String? peranLawanTransaksi;
  final DateTime? tenggat;
  final int? detikTersisa;
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

  static String _mapStatusEscrow(String statusKode, String? explicitEscrow) {
    if (explicitEscrow != null && explicitEscrow.isNotEmpty) {
      return explicitEscrow;
    }
    switch (statusKode) {
      case 'completed':
        return 'Dana Dilepas ke Penyedia';
      case 'rejected':
      case 'cancelled':
        return 'Dana Dikembalikan (Refund)';
      case 'completion_requested':
        return 'Menunggu Konfirmasi Pelanggan';
      case 'accepted':
      case 'in_progress':
        return 'Dana Ditahan Aman (Escrow)';
      case 'requested':
      case 'negotiating':
      default:
        return 'Menunggu Kesepakatan / Escrow';
    }
  }

  factory EscrowOrderModel.fromJson(Map<String, dynamic> json) {
    final snapshotGig = json['snapshot_gig'] as Map<String, dynamic>?;
    final kesepakatan = json['kesepakatan'] as Map<String, dynamic>?;
    final lawan = json['lawan_transaksi'] as Map<String, dynamic>?;
    final pembayaran = json['pembayaran'] as Map<String, dynamic>?;
    final brief = json['brief'] as Map<String, dynamic>?;
    final sla = json['sla'] as Map<String, dynamic>?;
    final deliverable = json['deliverable'] as Map<String, dynamic>?;
    final revisi = json['revisi'] as Map<String, dynamic>?;
    final proposals = json['proposals'] as List<dynamic>?;

    final orderId = (json['order_id'] ?? '') as String;
    final statusKode = (json['status_kode'] ?? 'requested') as String;

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

    final shortCode = orderId.length >= 8
        ? 'ORD-${orderId.substring(0, 8).toUpperCase()}'
        : orderId;

    final scopeText = (kesepakatan?['scope'] ??
        json['ruang_lingkup'] ??
        json['catatan_kebutuhan'] ??
        brief?['deskripsi']) as String?;

    final latestProposal = (proposals?.isNotEmpty ?? false)
        ? proposals!.last as Map<String, dynamic>?
        : null;

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
        (json['status_escrow'] ?? pembayaran?['status_dana_simulasi'])
            as String?,
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
      listingId: json['listing_id'] as String?,
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
      isTerlambat: computedLate,
      deskripsiBrief: scopeText,
      catatanBrief: (json['catatan_kebutuhan'] ??
          snapshotGig?['ketentuan'] ??
          json['snapshot_ketentuan'] ??
          brief?['catatan']) as String?,
      lampiranKlien: brief?['lampiran_klien'] as String?,
      tautanBerkas: deliverable?['tautan_berkas'] as String?,
      catatanPenyedia: (deliverable?['catatan_penyedia'] ??
          latestProposal?['deskripsi_ruang_lingkup']) as String?,
      mockupUrl: deliverable?['mockup_url'] as String?,
      batasRevisi: ((revisi?['batas_maksimal'] ?? 2) as num).toInt(),
      revisiTerpakai:
          ((revisi?['telah_digunakan'] ?? (proposals?.length ?? 0)) as num)
              .toInt(),
      sisaRevisi: ((revisi?['sisa_kesempatan'] ??
              (2 - (proposals?.length ?? 0)).clamp(0, 2)) as num)
          .toInt(),
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
    String? listingId,
    String? pelangganId,
    String? penyediaId,
    String? labelStepper,
    String? namaLawanTransaksi,
    String? peranLawanTransaksi,
    DateTime? tenggat,
    int? detikTersisa,
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
      listingId: listingId ?? this.listingId,
      pelangganId: pelangganId ?? this.pelangganId,
      penyediaId: penyediaId ?? this.penyediaId,
      labelStepper: labelStepper ?? this.labelStepper,
      namaLawanTransaksi: namaLawanTransaksi ?? this.namaLawanTransaksi,
      peranLawanTransaksi: peranLawanTransaksi ?? this.peranLawanTransaksi,
      tenggat: tenggat ?? this.tenggat,
      detikTersisa: detikTersisa ?? this.detikTersisa,
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