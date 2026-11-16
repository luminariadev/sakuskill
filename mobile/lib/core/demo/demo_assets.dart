/// Aset persona & portofolio demo dari Figma ("ASSET PERSONA & PORTOFOLIO").
///
/// Dipakai selama backend belum menyediakan URL foto. Ganti dengan
/// `Image.network` dari data profil saat API siap.
abstract final class DemoAssets {
  static const String salma = 'assets/images/portrait_salma.jpg';
  static const String dimas = 'assets/images/portrait_dimas.jpg';
  static const String rizkia = 'assets/images/portrait_rizkia.jpg';
  static const String spandukBerkah = 'assets/images/spanduk_berkah.jpg';
  static const String portfolioWeb = 'assets/images/portfolio_web.jpg';
  static const String portfolioInstagram =
      'assets/images/portfolio_instagram.jpg';

  /// Foto untuk nama penyedia yang dikenal di data contoh.
  static String? portraitFor(String name) {
    final n = name.toLowerCase();
    if (n.startsWith('salma')) return salma;
    if (n.startsWith('dimas')) return dimas;
    if (n.startsWith('rizkia')) return rizkia;
    return null;
  }
}
