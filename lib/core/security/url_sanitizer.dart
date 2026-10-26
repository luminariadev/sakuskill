class SecuritySanitizer {
  static final RegExp _safeUrlPattern = RegExp(
    r'^(https?:\/\/)([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?(\?.*)?$',
    caseSensitive: false,
  );

  static const List<String> forbiddenKeywords = [
    'joki tugas',
    'joki skripsi',
    'pengerjaan kuis',
    'joki uts',
    'joki uas',
    'turnitin bypass',
    'makalah siap saji',
  ];

  /// Validates that a deliverable URL uses secure HTTP/HTTPS protocol
  /// and prevents javascript:, file:, or data: malicious injection schemes.
  static bool isValidSecureUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final trimmed = url.trim();
    if (!trimmed.startsWith('https://') && !trimmed.startsWith('http://')) {
      return false;
    }
    return _safeUrlPattern.hasMatch(trimmed);
  }

  /// Checks for academic dishonesty or joki services violating campus ethics
  static bool containsForbiddenKeywords(String text) {
    final lower = text.toLowerCase();
    for (final word in forbiddenKeywords) {
      if (lower.contains(word)) return true;
    }
    return false;
  }
}
