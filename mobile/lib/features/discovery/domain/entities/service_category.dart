/// Kategori layanan — selaras dengan kolom `skills.kategori` (seed SKPL FR-23).
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.label,
    required this.iconKey,
  });

  /// Nilai persis seperti di backend (`skills.kategori`).
  final String id;
  final String label;

  /// Kunci ikon; dipetakan ke IconData di lapisan presentasi agar domain
  /// tidak bergantung pada Flutter.
  final String iconKey;

  @override
  bool operator ==(Object other) => other is ServiceCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
