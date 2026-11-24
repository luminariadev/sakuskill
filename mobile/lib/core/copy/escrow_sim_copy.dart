/// Copy terpusat untuk SIMULATED ESCROW (FR-58, FR-59, NFR-23) — persiapan K-02.
///
/// SakuSkill TIDAK menahan, menyimpan, atau menyalurkan uang. Pembayaran
/// diproses payment gateway; "status dana" hanya catatan simulasi.
///
/// ⚠️ STATUS: USULAN, BELUM DIPAKAI DI LAYAR.
/// Teks di layar baru diganti setelah UI/UX + PM (dan Anggota 8 untuk aspek
/// etika) menyetujui K-02. Daftar lokasi teks yang perlu diganti ada di
/// `docs/K02_COPY_SIMULASI.md`. Setelah disetujui, layar cukup mengimpor
/// konstanta ini agar wording seragam di semua modul.
abstract final class EscrowSimCopy {
  /// Keterangan wajib di setiap tampilan status dana (FR-59, AC-Escrow-01).
  static const String disclaimer =
      'Simulasi: dana tidak benar-benar ditahan oleh SakuSkill. Pembayaran '
      'diproses oleh payment gateway.';

  /// Versi pendek untuk ruang sempit (badge, kartu ringkas).
  static const String disclaimerShort = 'Status dana simulasi, bukan penahanan uang.';

  /// Keterangan untuk status `Ditahan (Simulasi)` (usulan PRD K-02).
  static const String heldNote =
      'Status dana: Ditahan (Simulasi). SakuSkill tidak menahan uang Anda; '
      'pembayaran diproses oleh payment gateway.';

  /// Pengganti banner "Uang Anda ditahan sistem…" di Beranda (usulan).
  static const String bannerTitle = 'Transaksi Tercatat & Terpantau';
  static const String bannerBody =
      'Setiap pesanan punya status yang jelas dari pembayaran sampai hasil '
      'disetujui. Status dana bersifat simulasi; pembayaran diproses oleh '
      'payment gateway.';

  /// Pengganti judul "Pembayaran Rekening Bersama" (layar 14, usulan).
  static const String paymentTitle = 'Pembayaran Pesanan';

  /// Pengganti CTA "Bayar & Kunci Dana di Escrow" (layar 14, usulan).
  static String payCta(String amount) => 'Bayar via Payment Gateway ($amount)';

  /// Pengganti "Dana telah diteruskan ke Saldo Dompet …" (layar 18, usulan).
  static String releasedNote(String provider) =>
      'Status dana: Dilepas (Simulasi). Pembayaran ke $provider diproses oleh '
      'payment gateway, bukan oleh SakuSkill.';

  /// Pengganti "Mengajukan komplain akan membekukan dana…" (layar 26, usulan).
  static const String complaintNote =
      'Pesanan akan berstatus Dalam Sengketa dan ditinjau Admin SakuSkill. '
      'Status dana simulasi tidak berubah sampai ada keputusan.';
}
