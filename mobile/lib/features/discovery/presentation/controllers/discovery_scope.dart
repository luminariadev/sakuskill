import 'package:material_ui/material_ui.dart';

import 'discovery_controller.dart';

/// Menyebarkan [DiscoveryController] ke subtree dan me-rebuild widget yang
/// memanggil [DiscoveryScope.of] ketika state berubah.
class DiscoveryScope extends InheritedNotifier<DiscoveryController> {
  const DiscoveryScope({
    super.key,
    required DiscoveryController controller,
    required super.child,
  }) : super(notifier: controller);

  static DiscoveryController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DiscoveryScope>();
    assert(scope != null, 'DiscoveryScope tidak ditemukan di atas widget ini.');
    return scope!.notifier!;
  }

  /// Akses tanpa berlangganan rebuild (untuk callback/onTap).
  static DiscoveryController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<DiscoveryScope>();
    assert(scope != null, 'DiscoveryScope tidak ditemukan di atas widget ini.');
    return scope!.notifier!;
  }
}
