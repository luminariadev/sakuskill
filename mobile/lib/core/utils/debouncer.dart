import 'dart:async';
import 'dart:ui' show VoidCallback;

/// Menunda eksekusi (mis. pencarian saat mengetik) agar tidak memanggil
/// repository di setiap ketukan tombol.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 300)});

  final Duration delay;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}
