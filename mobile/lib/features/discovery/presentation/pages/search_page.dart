import 'package:material_ui/material_ui.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/widgets/saku_pill.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/discovery_filter.dart';
import '../controllers/discovery_controller.dart';
import '../widgets/discovery_filters.dart';
import '../widgets/service_card.dart';

/// Halaman pencarian layanan: kata kunci + kategori + radius + Smart Barter.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.initialFilter = const DiscoveryFilter()});

  final DiscoveryFilter initialFilter;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _text =
      TextEditingController(text: widget.initialFilter.query);
  final Debouncer _debouncer = Debouncer();
  DiscoveryController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= AppScope.of(context)
        .createDiscoveryController(initialFilter: widget.initialFilter)
      ..init();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _text.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {}); // perbarui tombol clear
    _debouncer.run(() => _controller?.setQuery(value));
  }

  void _clear() {
    _text.clear();
    _controller?.setQuery('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextField(
                key: const Key('search-input'),
                controller: _text,
                autofocus: widget.initialFilter.query.isEmpty,
                textInputAction: TextInputAction.search,
                onChanged: _onQueryChanged,
                onSubmitted: (v) => controller.setQuery(v),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Cari jasa, keahlian, atau nama...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _text.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus',
                          onPressed: _clear,
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                ),
              ),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              CategoryChipsRow(
                categories: controller.categories,
                selectedId: controller.filter.categoryId,
                onSelected: controller.setCategory,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: AppSpacing.screen,
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: RadiusSegmented(
                          value: controller.filter.radiusMeters,
                          onChanged: controller.setRadius,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SakuPill(
                      label: 'Barter',
                      icon: Icons.swap_horiz_rounded,
                      tone: SakuPillTone.barter,
                      selected: controller.filter.barterOnly,
                      onTap: controller.toggleBarterOnly,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: AppSpacing.screen,
                child: Text(
                  controller.isLoading
                      ? 'Mencari...'
                      : '${controller.listings.length} jasa ditemukan · '
                          'radius ${radiusLabel(controller.filter.radiusMeters)}',
                  style: AppTypography.caption,
                ),
              ),
              if (controller.isFallback)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: OfflineDataBanner(),
                ),
              const SizedBox(height: 8),
              Expanded(child: _Results(controller: controller)),
            ],
          ),
        );
      },
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.controller});

  final DiscoveryController controller;

  @override
  Widget build(BuildContext context) {
    final listings = controller.listings;

    if (controller.isLoading && listings.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (controller.status == DiscoveryStatus.failure) {
      return EmptyStateView(
        icon: Icons.wifi_off_rounded,
        title: 'Ups, ada kendala',
        message: controller.errorMessage ?? 'Gagal memuat data.',
        actionLabel: 'Coba lagi',
        onAction: controller.refresh,
      );
    }
    if (listings.isEmpty) {
      return ListView(
        children: [
          EmptyStateView(
            icon: Icons.search_off_rounded,
            title: 'Tidak ada hasil',
            message: controller.filter.hasQuery
                ? 'Tidak ada jasa cocok dengan “${controller.filter.query}” '
                    'dalam radius ini.'
                : 'Belum ada jasa dalam radius ini.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: listings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final listing = listings[i];
        return ServiceCard(
          listing: listing,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.serviceDetail,
            arguments: listing,
          ),
        );
      },
    );
  }
}
