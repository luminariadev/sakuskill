/// Enum status baku SakuSkill (PRD §8.1, NFR-22).
///
/// Nilai [ApiEnum.apiValue] SAMA PERSIS dengan enum PostgreSQL di
/// `backend/migrations/001_init_sakuskill_schema.sql`. Tes
/// `test/core/domain/status_test.dart` membandingkan daftar ini langsung
/// dengan file migrasi, jadi perubahan enum DB akan langsung ketahuan.
///
/// Aturan pakai:
/// - Badge status di UI WAJIB memakai [ApiEnum.label] dari enum ini
///   (lihat `StatusPill` di `core/widgets/status_tones.dart`), bukan teks bebas.
/// - FE tidak menghitung transisi status sendiri. Aksi yang ditampilkan
///   berasal dari status + peran pengguna, dan server adalah validator akhir.
/// - Lapisan ini Dart murni: tidak boleh mengimpor Flutter.
library;

/// Kontrak bersama semua enum status: nilai API + label tampilan.
mixin ApiEnum on Enum {
  /// Nilai persis seperti di API/DB, mis. `"Dalam Negosiasi"`.
  String get apiValue;

  /// Label tampilan Indonesia. Untuk enum status sama dengan [apiValue]
  /// agar label konsisten di semua layar (NFR-22).
  String get label => apiValue;

  /// Nilai untuk dikirim ke API.
  String toJson() => apiValue;
}

/// Mencari nilai enum dari string API. Melempar [FormatException] bila
/// nilainya tidak dikenal (lebih baik gagal jelas daripada salah status).
T _parse<T extends ApiEnum>(List<T> values, Object? raw, String type) {
  for (final v in values) {
    if (v.apiValue == raw) return v;
  }
  throw FormatException('Nilai $type tidak dikenal: "$raw"');
}

T? _tryParse<T extends ApiEnum>(List<T> values, Object? raw) {
  for (final v in values) {
    if (v.apiValue == raw) return v;
  }
  return null;
}

/// `order_status_enum` — siklus pesanan jasa berbayar.
enum OrderStatus with ApiEnum {
  submitted('Diajukan'),
  rejected('Ditolak'),
  negotiating('Dalam Negosiasi'),
  agreed('Disepakati'),
  paid('Dibayar'),
  inProgress('Dikerjakan'),
  awaitingConfirmation('Menunggu Konfirmasi'),
  completed('Selesai'),
  cancelled('Dibatalkan'),
  disputed('Dalam Sengketa');

  const OrderStatus(this.apiValue);
  @override
  final String apiValue;

  static OrderStatus fromJson(Object? raw) =>
      _parse(values, raw, 'status pesanan');
  static OrderStatus? tryParse(Object? raw) => _tryParse(values, raw);
}

/// `barter_status_enum` — siklus kesepakatan Smart Barter.
enum BarterStatus with ApiEnum {
  submitted('Diajukan'),
  rejected('Ditolak'),
  discussing('Dalam Diskusi'),
  agreed('Disepakati'),
  executing('Dilaksanakan'),
  completed('Selesai'),
  cancelled('Dibatalkan'),
  disputed('Dalam Sengketa');

  const BarterStatus(this.apiValue);
  @override
  final String apiValue;

  static BarterStatus fromJson(Object? raw) =>
      _parse(values, raw, 'status barter');
  static BarterStatus? tryParse(Object? raw) => _tryParse(values, raw);
}

/// `barter_exec_status_enum` — status pelaksanaan per pihak dalam barter.
enum BarterExecStatus with ApiEnum {
  notStarted('Belum Dimulai'),
  inProgress('Dikerjakan'),
  done('Selesai Dikerjakan');

  const BarterExecStatus(this.apiValue);
  @override
  final String apiValue;

  static BarterExecStatus fromJson(Object? raw) =>
      _parse(values, raw, 'status pelaksanaan barter');
  static BarterExecStatus? tryParse(Object? raw) => _tryParse(values, raw);
}

/// `payment_status_enum` — status pembayaran lewat payment gateway.
enum PaymentStatus with ApiEnum {
  awaitingPayment('Menunggu Pembayaran'),
  awaitingVerification('Menunggu Verifikasi'),
  verified('Terverifikasi'),
  failed('Gagal'),
  cancelled('Dibatalkan');

  const PaymentStatus(this.apiValue);
  @override
  final String apiValue;

  static PaymentStatus fromJson(Object? raw) =>
      _parse(values, raw, 'status pembayaran');
  static PaymentStatus? tryParse(Object? raw) => _tryParse(values, raw);
}

/// `escrow_sim_status_enum` — status dana SIMULASI (FR-58/59).
///
/// SakuSkill tidak benar-benar menahan uang. Setiap tampilan status ini wajib
/// disertai keterangan simulasi (FR-59, NFR-23); copy-nya menunggu K-02.
enum EscrowSimStatus with ApiEnum {
  noFunds('Belum Ada Dana'),
  held('Ditahan (Simulasi)'),
  released('Dilepas (Simulasi)'),
  refunded('Dikembalikan (Simulasi)');

  const EscrowSimStatus(this.apiValue);
  @override
  final String apiValue;

  static EscrowSimStatus fromJson(Object? raw) =>
      _parse(values, raw, 'status dana simulasi');
  static EscrowSimStatus? tryParse(Object? raw) => _tryParse(values, raw);
}

/// `report_status_enum` — status laporan/pengaduan.
enum ReportStatus with ApiEnum {
  submitted('Baru'),
  reviewing('Ditinjau'),
  resolved('Selesai');

  const ReportStatus(this.apiValue);
  @override
  final String apiValue;

  static ReportStatus fromJson(Object? raw) =>
      _parse(values, raw, 'status laporan');
  static ReportStatus? tryParse(Object? raw) => _tryParse(values, raw);
}

/// `verification_status_enum` — status verifikasi akun (FR-10).
enum VerificationStatus with ApiEnum {
  unverified('Belum Terverifikasi'),
  verified('Terverifikasi'),
  rejected('Ditolak');

  const VerificationStatus(this.apiValue);
  @override
  final String apiValue;

  static VerificationStatus fromJson(Object? raw) =>
      _parse(values, raw, 'status verifikasi');
  static VerificationStatus? tryParse(Object? raw) => _tryParse(values, raw);
}

/// `offer_type_enum` — tipe penawaran listing.
enum OfferType with ApiEnum {
  paid('Berbayar'),
  barter('Barter'),
  paidAndBarter('Berbayar dan Barter');

  const OfferType(this.apiValue);
  @override
  final String apiValue;

  bool get acceptsBarter => this != OfferType.paid;
  bool get acceptsPayment => this != OfferType.barter;

  static OfferType fromJson(Object? raw) =>
      _parse(values, raw, 'tipe penawaran');
  static OfferType? tryParse(Object? raw) => _tryParse(values, raw);

  /// Parser longgar untuk data listing lama: nilai asing → [OfferType.paid].
  static OfferType fromApi(String? value) => tryParse(value) ?? OfferType.paid;
}
