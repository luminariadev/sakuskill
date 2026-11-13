/// Format Rupiah tanpa paket `intl`: 35000 -> "Rp 35.000".
String formatRupiah(num amount) {
  final value = amount.round();
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return '${negative ? '-' : ''}Rp $buffer';
}

/// Inisial nama untuk avatar: "Ahmad Fauzi" -> "AF".
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  final letters = parts.take(2).map((p) => p[0].toUpperCase());
  return letters.join();
}
