// Model dan aturan bisnis Escrow (sisi tampilan).
//
// Sengaja murni Dart (tanpa import Flutter) supaya mudah diuji oleh Anggota 7.
// Catatan: entitas `EscrowOrder` di domain/ milik Anggota 5. File ini bukan
// penggantinya; ini model untuk layar yang nanti dipetakan dari entitas itu.

/// Seluruh status sebuah pesanan, mengikuti alur di Figma.
enum EscrowStatus {
  menungguRespons, // 12  penyedia belum menjawab
  ditolak, //          12B penyedia menolak
  diskusiBrief, //     13  sepakat brief lewat chat
  menungguPembayaran, // 14 klien membayar ke Rekening Bersama
  dikerjakan, //       14B/15 penyedia mengerjakan
  buktiDikirim, //     16/17 menunggu pemeriksaan klien
  selesai, //          18
  terlambat, //        15D melewati tenggat
  dibatalkan, //       15D-2 klien membatalkan dan menarik dana
  banding, //          15E penyedia mengajukan banding
  sengketa, //         komplain dari layar 17/26
}

extension EscrowStatusInfo on EscrowStatus {
  String get label {
    switch (this) {
      case EscrowStatus.menungguRespons:
        return 'Menunggu respons';
      case EscrowStatus.ditolak:
        return 'Ditolak';
      case EscrowStatus.diskusiBrief:
        return 'Diskusi brief';
      case EscrowStatus.menungguPembayaran:
        return 'Menunggu pembayaran';
      case EscrowStatus.dikerjakan:
        return 'Dikerjakan';
      case EscrowStatus.buktiDikirim:
        return 'Bukti dikirim';
      case EscrowStatus.selesai:
        return 'Selesai';
      case EscrowStatus.terlambat:
        return 'Terlambat';
      case EscrowStatus.dibatalkan:
        return 'Dibatalkan';
      case EscrowStatus.banding:
        return 'Banding';
      case EscrowStatus.sengketa:
        return 'Sengketa';
    }
  }

  /// Status yang tidak bisa pindah lagi.
  bool get isAkhir => this == EscrowStatus.selesai || this == EscrowStatus.ditolak;
}

/// Perpindahan status yang boleh. Selain ini dianggap salah.
const Map<EscrowStatus, Set<EscrowStatus>> _alur = {
  EscrowStatus.menungguRespons: {EscrowStatus.diskusiBrief, EscrowStatus.ditolak},
  EscrowStatus.diskusiBrief: {EscrowStatus.menungguPembayaran, EscrowStatus.dibatalkan},
  EscrowStatus.menungguPembayaran: {EscrowStatus.dikerjakan, EscrowStatus.dibatalkan},
  EscrowStatus.dikerjakan: {EscrowStatus.buktiDikirim, EscrowStatus.terlambat},
  // Terlambat bisa kembali jalan bila klien memberi kesempatan.
  EscrowStatus.terlambat: {
    EscrowStatus.dikerjakan,
    EscrowStatus.buktiDikirim,
    EscrowStatus.dibatalkan,
  },
  // Revisi ringan mengembalikan pesanan ke "dikerjakan".
  EscrowStatus.buktiDikirim: {
    EscrowStatus.selesai,
    EscrowStatus.dikerjakan,
    EscrowStatus.sengketa,
  },
  // Hasil banding dan sengketa diputuskan Admin.
  EscrowStatus.dibatalkan: {EscrowStatus.banding},
  EscrowStatus.banding: {EscrowStatus.dibatalkan, EscrowStatus.selesai},
  EscrowStatus.sengketa: {EscrowStatus.selesai, EscrowStatus.dibatalkan},
};

/// Angka aturan dari layar Figma. Ubah di sini saja bila tim mengubah aturan.
class EscrowRules {
  const EscrowRules._();

  /// Masa tenggang setelah tenggat lewat (layar 15D: "masa tenggang 24 jam").
  static const masaTenggang = Duration(hours: 24);

  /// Klien boleh batal sepihak setelah terlambat lebih dari ini.
  static const batasBatalSepihak = Duration(hours: 12);

  /// Penyedia boleh banding bila progres lebih dari ini (persen).
  static const ambangBanding = 70;

  /// Kuota revisi ringan ("2x revisi minor").
  static const kuotaRevisi = 2;

  /// Peringatan amber muncul saat sisa waktu kurang dari ini.
  static const peringatanDini = Duration(hours: 6);

  /// Pilihan tambahan waktu (layar 15B).
  static const opsiTambahanJam = [6, 12, 24];

  static bool boleBatalSepihak(Duration terlambat) => terlambat > batasBatalSepihak;

  static bool boleBanding(int progresPersen) => progresPersen > ambangBanding;

  static bool peringatanDiniAktif(Duration sisa) =>
      !sisa.isNegative && sisa < peringatanDini;
}

/// Model satu pesanan untuk layar. Immutable: ubah lewat copyWith/pindahKe.
class PesananEscrow {
  const PesananEscrow({
    required this.kode,
    required this.judul,
    required this.namaKlien,
    required this.namaPenyedia,
    required this.harga,
    required this.status,
    this.biayaLayanan = 0,
    this.durasi = const Duration(days: 3),
    this.tenggat,
    this.revisiTerpakai = 0,
    this.progres = 0,
    this.buktiUrl,
  });

  final String kode;
  final String judul;
  final String namaKlien;
  final String namaPenyedia;
  final int harga;
  final int biayaLayanan;
  final EscrowStatus status;
  final Duration durasi;

  /// Terisi saat pesanan mulai dikerjakan (setelah pembayaran).
  final DateTime? tenggat;
  final int revisiTerpakai;
  final int progres;
  final String? buktiUrl;

  /// "Salma Nur Oktavia" -> "Salma"
  String get panggilanPenyedia => namaPenyedia.split(' ').first;
  String get panggilanKlien => namaKlien.split(' ').first;

  int get total => harga + biayaLayanan;

  int get sisaRevisi => EscrowRules.kuotaRevisi - revisiTerpakai;

  /// Positif = masih ada waktu, negatif = sudah lewat.
  Duration sisaWaktu(DateTime sekarang) =>
      tenggat == null ? Duration.zero : tenggat!.difference(sekarang);

  Duration terlambatSejak(DateTime sekarang) {
    final s = sisaWaktu(sekarang);
    return s.isNegative ? -s : Duration.zero;
  }

  bool bisaPindahKe(EscrowStatus tujuan) =>
      (_alur[status] ?? const <EscrowStatus>{}).contains(tujuan);

  /// Pindah status; melempar StateError bila perpindahannya tidak diizinkan.
  PesananEscrow pindahKe(EscrowStatus tujuan) {
    if (!bisaPindahKe(tujuan)) {
      throw StateError('Tidak boleh pindah dari ${status.name} ke ${tujuan.name}');
    }
    return copyWith(status: tujuan);
  }

  PesananEscrow copyWith({
    EscrowStatus? status,
    DateTime? tenggat,
    int? revisiTerpakai,
    int? progres,
    String? buktiUrl,
  }) {
    return PesananEscrow(
      kode: kode,
      judul: judul,
      namaKlien: namaKlien,
      namaPenyedia: namaPenyedia,
      harga: harga,
      biayaLayanan: biayaLayanan,
      status: status ?? this.status,
      durasi: durasi,
      tenggat: tenggat ?? this.tenggat,
      revisiTerpakai: revisiTerpakai ?? this.revisiTerpakai,
      progres: progres ?? this.progres,
      buktiUrl: buktiUrl ?? this.buktiUrl,
    );
  }

  /// Data contoh sesuai Figma (SK-2026-091). Ganti dengan data repository nanti.
  /// [sisaWaktu] negatif berarti sudah lewat tenggat.
  factory PesananEscrow.contoh({
    EscrowStatus status = EscrowStatus.menungguPembayaran,
    Duration? sisaWaktu,
    int progres = 0,
    int revisiTerpakai = 1,
    String? buktiUrl,
  }) =>
      PesananEscrow(
        kode: 'SK-2026-091',
        judul: 'Desain Spanduk Katering Berkah',
        namaKlien: 'Dimas',
        namaPenyedia: 'Salma Nur Oktavia',
        harga: 50000,
        status: status,
        tenggat: sisaWaktu == null ? null : DateTime.now().add(sisaWaktu),
        progres: progres,
        revisiTerpakai: revisiTerpakai,
        buktiUrl: buktiUrl,
      );
}

/// 50000 -> "Rp 50.000"
String formatRupiah(int v) {
  final s = v.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}Rp $buf';
}

/// Validasi tautan bukti: wajib https. Sementara; ganti dengan url_sanitizer
/// milik Anggota 6 bila sudah bisa dipakai.
bool isHttpsUrl(String? url) {
  if (url == null) return false;
  final u = Uri.tryParse(url.trim());
  return u != null && u.scheme == 'https' && u.host.isNotEmpty;
}