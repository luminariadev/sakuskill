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

/// Format jam real-time: 14:35 WIB.
String formatTimeWib(DateTime dt) {
  final local = dt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m WIB';
}

/// Format jam dan detik real-time: 14:35:09 WIB.
String formatClockSeconds(DateTime dt) {
  final local = dt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  final s = local.second.toString().padLeft(2, '0');
  return '$h:$m:$s WIB';
}

/// Format waktu relatif dinamis (e.g. "Baru saja", "5 mnt lalu", "Hari ini, 14:35 WIB").
String formatRelativeTime(DateTime dt, {DateTime? baseTime}) {
  final now = baseTime ?? DateTime.now();
  final diff = now.difference(dt);

  if (diff.isNegative || diff.inSeconds < 45) {
    return 'Baru saja';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} mnt lalu';
  }

  final localDt = dt.toLocal();
  final localNow = now.toLocal();
  final isToday = localDt.year == localNow.year &&
      localDt.month == localNow.month &&
      localDt.day == localNow.day;

  if (isToday) {
    return formatTimeWib(localDt);
  }

  final yesterday = localNow.subtract(const Duration(days: 1));
  final isYesterday = localDt.year == yesterday.year &&
      localDt.month == yesterday.month &&
      localDt.day == yesterday.day;

  if (isYesterday) {
    return 'Kemarin, ${formatTimeWib(localDt)}';
  }

  if (diff.inDays < 7) {
    return '${diff.inDays} hari lalu';
  }

  final d = localDt.day.toString().padLeft(2, '0');
  final m = localDt.month.toString().padLeft(2, '0');
  return '$d/$m/${localDt.year}';
}

/// Format log audit dengan stempel waktu lengkap: [24 Nov 14:35:22 WIB].
String formatAuditTimestamp(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  final local = dt.toLocal();
  final d = local.day;
  final monthStr = months[local.month - 1];
  return '[$d $monthStr ${formatClockSeconds(local)}]';
}

