import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Micro-interaction SakuSkill — ultra-ringan dioptimalkan untuk layar 90–120Hz:
/// durasi mikro 80–180 ms, kurva easeOutCubic, animasi berbasis GPU layer
/// (FadeTransition & SlideTransition tanpa alokasi buffer offscreen rekursif).
abstract final class SakuMotion {
  static const Duration fast = Duration(milliseconds: 80);
  static const Duration base = Duration(milliseconds: 140);
  static const Duration slow = Duration(milliseconds: 180);
  static const Curve curve = Curves.easeOutCubic;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Getar ringan untuk aksi penting (kirim, konfirmasi, toggle).
  static void tick() => HapticFeedback.selectionClick();
}

/// Mengecil sedikit (0.97) saat ditekan lalu kembali — umpan balik sentuh
/// untuk tombol & kartu tanpa efek berlebihan.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (!widget.enabled || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = SakuMotion.reduced(context);
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && !reduced ? widget.scale : 1,
        duration: SakuMotion.fast,
        curve: SakuMotion.curve,
        child: widget.onTap == null
            ? widget.child
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.enabled ? widget.onTap : null,
                child: widget.child,
              ),
      ),
    );
  }
}

/// Muncul dengan fade + geser 10 px ke atas, sekali saat pertama dibangun.
/// [index] memberi jeda bertahap (stagger 40 ms, maksimal 8 item) untuk
/// daftar — terasa hidup tapi tetap cepat.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 10,
  });

  final Widget child;
  final int index;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  // Jeda stagger mikro (20 ms per indeks, maksimal 6 item) untuk daftar cepat & ringan.
  late final int _delayMs = 20 * widget.index.clamp(0, 6);
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: SakuMotion.slow.inMilliseconds + _delayMs),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      _delayMs / (SakuMotion.slow.inMilliseconds + _delayMs),
      1,
      curve: SakuMotion.curve,
    ),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(0, (widget.offset / 200).clamp(0.02, 0.08)),
    end: Offset.zero,
  ).animate(_t);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SakuMotion.reduced(context)) {
      _c.value = 1;
    } else if (_c.status == AnimationStatus.dismissed) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (SakuMotion.reduced(context)) return widget.child;
    return FadeTransition(
      opacity: _t,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Transisi halaman: fade + geser 4% dari kanan (Android & iOS seragam).
class SakuPageTransitionsBuilder extends PageTransitionsBuilder {
  const SakuPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (SakuMotion.reduced(context)) return child;
    final a = CurvedAnimation(parent: animation, curve: SakuMotion.curve);
    final out = CurvedAnimation(
      parent: secondaryAnimation,
      curve: SakuMotion.curve,
    );
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0.04, 0), end: Offset.zero)
            .animate(a),
        child: SlideTransition(
          position: Tween(begin: Offset.zero, end: const Offset(-0.02, 0))
              .animate(out),
          child: child,
        ),
      ),
    );
  }
}
