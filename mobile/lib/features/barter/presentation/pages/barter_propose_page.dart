import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_sheets.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../auth/data/auth_session.dart';
import '../../../discovery/domain/entities/discovery_filter.dart';
import '../../../discovery/domain/entities/service_listing.dart';
import '../../data/datasources/barter_remote_data_source.dart';

/// Hasil pencocokan Smart Barter 2 arah (pemisahan ketat apa yang
/// dibutuhkan pencari vs apa yang benar-benar ditawarkan mitra).
@immutable
class BarterMatchResult {
  const BarterMatchResult({
    required this.listing,
    required this.needScore,
    required this.offerScore,
    required this.needMatched,
    required this.isMutualMatch,
  });

  final ServiceListing listing;
  final int needScore;
  final int offerScore;
  final bool needMatched;
  final bool isMutualMatch;
}

const Set<String> _barterStopWords = {
  'jasa',
  'yang',
  'dan',
  'atau',
  'di',
  'ke',
  'dari',
  'untuk',
  'dengan',
  'bantuan',
  'keahlian',
  'saya',
  'anda',
  'kamu',
  'kami',
  'buat',
  'bikin',
  'tolong',
  'butuh',
  'cari',
  'dicari',
  'mencari',
  'layanan',
  'pro',
};

String _canonicalSkillToken(String raw) {
  final t = raw.toLowerCase().trim();
  if (t.isEmpty) return '';
  if (t.startsWith('edit')) return 'edit';
  if (t.startsWith('desain') || t.startsWith('design')) return 'desain';
  if (t.startsWith('foto') || t.startsWith('photo')) return 'foto';
  if (t.startsWith('instal')) return 'install';
  if (t.startsWith('pemrogram') ||
      t.startsWith('program') ||
      t == 'coding' ||
      t == 'koding' ||
      t == 'coder') {
    return 'program';
  }
  if (t.startsWith('bimbing') || t == 'tutor' || t == 'tutoring') {
    return 'bimbingan';
  }
  if (t == 'graphic' || t == 'grafik') return 'grafis';
  return t;
}

Set<String> _tokenizeSkillQuery(String text) {
  final parts = text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'));
  final tokens = <String>{};
  for (final raw in parts) {
    if (raw.length < 2 || _barterStopWords.contains(raw)) continue;
    final canonical = _canonicalSkillToken(raw);
    if (canonical.length >= 2) tokens.add(canonical);
  }
  return tokens;
}

int _scoreTextAgainstTokens(String haystack, Set<String> queryTokens) {
  if (queryTokens.isEmpty || haystack.trim().isEmpty) return 0;
  final hayTokens = _tokenizeSkillQuery(haystack);
  final hayLower = haystack.toLowerCase();
  var hits = 0;
  for (final token in queryTokens) {
    if (hayTokens.contains(token) || hayLower.contains(token)) {
      hits++;
    }
  }
  return hits;
}

/// Mencocokkan kandidat barter secara akurat:
/// - [needQuery] dicocokkan HANYA ke layanan yang DITAWARKAN mitra (`title`,
///   `skillName`, `category`, `description`), tidak pernah ke `barterWant`.
/// - [offerQuery] dicocokkan ke `barterWant` (kebutuhan imbalan mitra) untuk
///   menentukan kecocokan 2 arah (`isMutualMatch`).
List<BarterMatchResult> matchBarterCandidates({
  required List<ServiceListing> candidates,
  required String needQuery,
  String offerQuery = '',
  String? currentUserName,
}) {
  final myName = (currentUserName ?? '').trim().toLowerCase();
  final needTokens = _tokenizeSkillQuery(needQuery);
  final offerTokens = _tokenizeSkillQuery(offerQuery);

  final results = <BarterMatchResult>[];
  for (final item in candidates) {
    final supportsBarter = item.offerType == OfferType.barter ||
        item.offerType == OfferType.paidAndBarter;
    if (!supportsBarter) continue;
    if (myName.isNotEmpty &&
        item.providerName.trim().toLowerCase() == myName) {
      continue;
    }

    final titleHits = _scoreTextAgainstTokens(item.title, needTokens);
    final skillHits = _scoreTextAgainstTokens(
      '${item.skillName} ${item.category}',
      needTokens,
    );
    final descHits = _scoreTextAgainstTokens(item.description, needTokens);
    final needScore = (titleHits * 4) + (skillHits * 3) + descHits;

    if (needTokens.isNotEmpty && needScore == 0) {
      continue;
    }

    final wantText = item.barterWant ?? '';
    final offerHits = _scoreTextAgainstTokens(wantText, offerTokens);
    final offerScore = offerHits * 3;

    if (needTokens.isEmpty && offerTokens.isNotEmpty && offerScore == 0) {
      continue;
    }

    final needMatched = needTokens.isNotEmpty && needScore > 0;
    final offerMatched = offerTokens.isNotEmpty && offerScore > 0;
    final isMutualMatch = needTokens.isNotEmpty
        ? (needMatched && offerMatched)
        : offerMatched;

    results.add(
      BarterMatchResult(
        listing: item,
        needScore: needScore,
        offerScore: offerScore,
        needMatched: needMatched,
        isMutualMatch: isMutualMatch,
      ),
    );
  }

  results.sort((a, b) {
    if (a.isMutualMatch != b.isMutualMatch) {
      return a.isMutualMatch ? -1 : 1;
    }
    final needCmp = b.needScore.compareTo(a.needScore);
    if (needCmp != 0) return needCmp;
    final offerCmp = b.offerScore.compareTo(a.offerScore);
    if (offerCmp != 0) return offerCmp;
    final distA = a.listing.distanceMeters ?? double.infinity;
    final distB = b.listing.distanceMeters ?? double.infinity;
    return distA.compareTo(distB);
  });

  return results;
}

/// Figma "19 · Buat penawaran barter" — mengajukan pertukaran jasa Rp 0.
/// Ketika [targetListing] tersedia (dibuka dari Detail Layanan), langsung
/// mengirim ke `POST /api/v1/barter`. Ketika dibuka langsung dari menu Barter
/// di mode live, melakukan Smart Matching ke layanan barter real dari backend.
class BarterProposePage extends StatefulWidget {
  const BarterProposePage({
    super.key,
    this.targetListing,
    this.initialCandidates,
  });

  final ServiceListing? targetListing;
  final List<ServiceListing>? initialCandidates;

  @override
  State<BarterProposePage> createState() => _BarterProposePageState();
}

class _BarterProposePageState extends State<BarterProposePage> {
  static const _offerOptions = [
    'Desain UI Web / Portofolio Grafis',
    'Desain Feed & Story Instagram',
    'Desain Spanduk Cetak',
  ];
  static const _wantOptions = [
    'Editing Video Teaser Reels / TikTok',
    'Web Frontend (Landing Page)',
    'Fotografi Produk',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _offerCtrl;
  late final TextEditingController _wantCtrl;
  final _matchQueryCtrl = TextEditingController();
  final _offerQueryCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: '4');
  final _portfolioCtrl = TextEditingController();

  int _offer = 0;
  int _want = 0;
  bool _submitting = false;
  bool _loadingMatches = false;
  bool _loadedMatches = false;
  List<ServiceListing> _barterCandidates = const [];
  ServiceListing? _selectedMatch;

  @override
  void initState() {
    super.initState();
    final target = widget.targetListing;
    _offerCtrl = TextEditingController(
      text: target?.barterWant != null
          ? 'Saya menawarkan bantuan keahlian: ${target!.barterWant}'
          : '',
    );
    _wantCtrl = TextEditingController(
      text: target != null ? 'Layanan ${target.title}' : '',
    );
    final preset = widget.initialCandidates;
    if (preset != null) {
      _loadedMatches = true;
      _barterCandidates = preset;
      final initialMatches = _filteredCandidates();
      if (initialMatches.isNotEmpty) {
        _selectCandidate(initialMatches.first.listing);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedMatches &&
        widget.targetListing == null &&
        !AppConfig.useMockData) {
      _loadedMatches = true;
      _loadSmartMatches();
    }
  }

  @override
  void dispose() {
    _offerCtrl.dispose();
    _wantCtrl.dispose();
    _matchQueryCtrl.dispose();
    _offerQueryCtrl.dispose();
    _daysCtrl.dispose();
    _portfolioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSmartMatches() async {
    setState(() => _loadingMatches = true);
    try {
      final result = await AppScope.of(context).discoveryRepository.searchNearby(
            const DiscoveryFilter(
              barterOnly: true,
              radiusMeters: 10000,
            ),
          );
      if (!mounted) return;
      final candidates = matchBarterCandidates(
        candidates: result.listings,
        needQuery: _matchQueryCtrl.text,
        offerQuery: _offerQueryCtrl.text,
        currentUserName: AuthSession.instance.fullName,
      );

      setState(() {
        _barterCandidates = result.listings;
        _selectedMatch =
            candidates.isNotEmpty ? candidates.first.listing : null;
        if (_selectedMatch != null) {
          _selectCandidate(_selectedMatch!);
        }
      });
    } catch (_) {
      // Abaikan jika gagal memuat sementara
    } finally {
      if (mounted) setState(() => _loadingMatches = false);
    }
  }

  void _selectCandidate(ServiceListing item) {
    _selectedMatch = item;
    if (_offerCtrl.text.trim().isEmpty ||
        _offerCtrl.text.startsWith('Saya menawarkan bantuan keahlian:')) {
      final typedOffer = _offerQueryCtrl.text.trim();
      final offered = typedOffer.isNotEmpty
          ? typedOffer
          : (item.barterWant != null && item.barterWant!.isNotEmpty
              ? item.barterWant!
              : '');
      _offerCtrl.text = offered.isNotEmpty
          ? 'Saya menawarkan bantuan keahlian: $offered'
          : 'Saya menawarkan bantuan keahlian yang sesuai kebutuhan Anda';
    }
    if (_wantCtrl.text.trim().isEmpty || _wantCtrl.text.startsWith('Layanan ')) {
      _wantCtrl.text = 'Layanan ${item.title}';
    }
  }

  List<BarterMatchResult> _filteredCandidates() => matchBarterCandidates(
        candidates: _barterCandidates,
        needQuery: _matchQueryCtrl.text,
        offerQuery: _offerQueryCtrl.text,
        currentUserName: AuthSession.instance.fullName,
      );

  void _onMatchFilterChanged() {
    setState(() {
      final matches = _filteredCandidates();
      if (matches.isEmpty) {
        _selectedMatch = null;
      } else if (_selectedMatch == null ||
          !matches.any((m) => m.listing.id == _selectedMatch!.id)) {
        _selectCandidate(matches.first.listing);
      }
    });
  }

  Future<void> _pick(
    String title,
    List<String> options,
    int current,
    ValueChanged<int> onPicked,
  ) async {
    var selected = current;
    final picked = await showSakuSheet<int>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SakuSheetContent(
          title: title,
          body: [
            RadioOptions(
              options: options,
              selected: selected,
              activeColor: AppColors.barter,
              fontSize: 13,
              onChanged: (i) => setSheet(() => selected = i),
            ),
          ],
          confirmLabel: 'Pilih',
          confirmVariant: SakuButtonVariant.barter,
          onConfirm: () => Navigator.of(ctx).pop(selected),
        ),
      ),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? true) || _submitting) return;
    SakuMotion.tick();

    if (AppConfig.useMockData) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.barterOffer);
      return;
    }

    final target = widget.targetListing ?? _selectedMatch;
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pilih salah satu mitra hasil Smart Matching terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final days = (int.tryParse(_daysCtrl.text.trim()) ?? 4).clamp(1, 90);
      final link = _portfolioCtrl.text.trim();
      final offerDesc = link.isNotEmpty
          ? '${_offerCtrl.text.trim()} (Portofolio: $link)'
          : _offerCtrl.text.trim();

      final created = await AppScope.of(context)
          .barterDataSource
          .createBarterOffer(
            listingId: target.id,
            deskripsiJasaPengaju: offerDesc,
            deskripsiJasaPenerima: _wantCtrl.text.trim(),
            tenggatPekerjaan: DateTime.now().toUtc().add(Duration(days: days)),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Penawaran barter terkirim ke ${target.providerName}! Menunggu persetujuan mitra.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.barterWorkroom,
        arguments: created,
      );
    } on BarterException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim tawaran barter: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.targetListing ?? _selectedMatch;
    final matches = _filteredCandidates();

    return Form(
      key: _formKey,
      child: SakuScreen(
        background: AppColors.canvasLight,
        showBack: true,
        gap: 13,
        children: [
          const PageHeader('Buat Penawaran\nBarter Baru'),
          const InfoBox(
            text:
                'Smart Barter Rp 0: Kedua pihak saling bertukar keahlian tanpa transaksi uang. Kontrak dimulai setelah kedua pihak menyetujui ruang lingkup & tenggat.',
            tone: SakuTone.barter,
            fontWeight: FontWeight.w500,
          ),
          if (!AppConfig.useMockData) ...[
            if (widget.targetListing == null) ...[
              SakuTextField(
                key: const Key('barter-match-search'),
                controller: _matchQueryCtrl,
                label: 'Keahlian yang Anda Cari / Butuhkan',
                hint: 'Contoh: Edit Video, Desain Poster, Fotografi...',
                onChanged: (_) => _onMatchFilterChanged(),
              ),
              SakuTextField(
                key: const Key('barter-match-offer-search'),
                controller: _offerQueryCtrl,
                label: 'Keahlian yang Anda Tawarkan (Opsional)',
                hint: 'Contoh: Desain UI, Install Laptop, Edit Reels...',
                onChanged: (_) => _onMatchFilterChanged(),
              ),
              if (_loadingMatches)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (matches.isEmpty)
                SakuCard(
                  key: const Key('barter-match-empty'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      const Text(
                        'Belum ditemukan mitra yang menawarkan keahlian yang Anda cari.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SakuButton(
                        label: 'Tampilkan Semua Mitra Barter',
                        variant: SakuButtonVariant.outline,
                        onPressed: () {
                          _matchQueryCtrl.clear();
                          _offerQueryCtrl.clear();
                          _onMatchFilterChanged();
                        },
                      ),
                    ],
                  ),
                )
              else ...[
                SectionLabel(
                  'MITRA COCOK (${matches.length}) — KETUK UNTUK MEMILIH',
                  key: const Key('barter-match-section'),
                  color: AppColors.barterText,
                ),
                for (final match in matches.take(5))
                  _MatchCandidateCard(
                    key: ValueKey('match-${match.listing.id}'),
                    match: match,
                    selected: _selectedMatch?.id == match.listing.id,
                    onTap: () => setState(() => _selectCandidate(match.listing)),
                  ),
              ],
            ],
            if (target != null)
              SakuCard(
                key: const Key('barter-target-card'),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    const SectionLabel('LAYANAN SASARAN BARTER',
                        color: AppColors.barterText),
                    Text(
                      target.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Penyedia: ${target.providerName} · Menawarkan: ${target.title}'
                      '${target.barterWant != null && target.barterWant!.isNotEmpty ? '\nMencari imbalan: ${target.barterWant}' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 17 / 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            SakuTextField(
              key: const Key('barter-offer-desc'),
              controller: _offerCtrl,
              label: 'Keahlian yang Saya Tawarkan (min. 10 karakter)',
              hint: 'Jelaskan jasa balasan yang akan Anda kerjakan...',
              minLines: 2,
              maxLines: 4,
              validator: SakuValidators.compose([
                SakuValidators.required('Keahlian yang ditawarkan'),
                SakuValidators.minLength(10),
              ]),
            ),
            SakuTextField(
              key: const Key('barter-want-desc'),
              controller: _wantCtrl,
              label: 'Layanan yang Saya Harapkan dari Mitra (min. 10 karakter)',
              minLines: 2,
              maxLines: 4,
              validator: SakuValidators.compose([
                SakuValidators.required('Layanan yang dibutuhkan'),
                SakuValidators.minLength(10),
              ]),
            ),
            SakuTextField(
              key: const Key('barter-days-input'),
              controller: _daysCtrl,
              label: 'Estimasi Durasi Pengerjaan Bersama (Hari)',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: SakuValidators.positiveNumber(),
            ),
          ] else ...[
            SakuTextField(
              key: ValueKey('offer-$_offer'),
              label: 'Jasa yang Saya Tawarkan',
              initialValue: '${_offerOptions[_offer]}  ⌄',
              readOnly: true,
              onTap: () => _pick('Jasa yang Saya Tawarkan', _offerOptions,
                  _offer, (i) => setState(() => _offer = i)),
            ),
            SakuTextField(
              key: ValueKey('want-$_want'),
              label: 'Jasa yang Saya Cari / Butuhkan',
              initialValue: '${_wantOptions[_want]}  ⌄',
              readOnly: true,
              onTap: () => _pick('Jasa yang Saya Cari', _wantOptions, _want,
                  (i) => setState(() => _want = i)),
            ),
            const SakuTextField(
              key: Key('barter-demo-days'),
              label: 'Estimasi Durasi Pengerjaan Bersama',
              initialValue: '4 Hari',
            ),
            const SakuTextField(
              key: Key('barter-demo-desc'),
              label: 'Deskripsi Rencana Kolaborasi',
              initialValue:
                  'Saya mencari mitra yang bisa mengedit video teaser 30 detik '
                  'untuk portofolio, saya akan membalas dengan mendesain landing page '
                  'UI web modern.',
              minLines: 3,
              maxLines: 6,
            ),
          ],
          SakuTextField(
            key: const Key('barter-portfolio-input'),
            controller: _portfolioCtrl,
            label: 'Tautan Portofolio Karya (Opsional)',
            hint: 'https://behance.net/karya-anda',
            keyboardType: TextInputType.url,
            validator: SakuValidators.optional(SakuValidators.httpsUrl()),
          ),
          SakuButton(
            key: const Key('barter-publish'),
            label: _submitting
                ? 'Mengirim Penawaran Barter...'
                : (!AppConfig.useMockData && target == null
                    ? 'Pilih Mitra yang Sesuai Dahulu'
                    : 'Kirim Penawaran Barter ke ${target?.providerName.split(' ').first ?? 'Mitra'}'),
            variant: SakuButtonVariant.barter,
            onPressed:
                (_submitting || (!AppConfig.useMockData && target == null))
                    ? null
                    : _submit,
          ),
        ],
      ),
    );
  }
}

class _MatchCandidateCard extends StatelessWidget {
  const _MatchCandidateCard({
    super.key,
    required this.match,
    required this.selected,
    required this.onTap,
  });

  final BarterMatchResult match;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final listing = match.listing;
    return SakuCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          InitialsAvatar(name: listing.providerName, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                if (match.isMutualMatch || match.needMatched)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: match.isMutualMatch
                          ? AppColors.primarySurface
                          : AppColors.barterSurface,
                      borderRadius: AppRadius.pillBr,
                    ),
                    child: Text(
                      match.isMutualMatch
                          ? '★ Cocok 2 Arah'
                          : '✓ Sesuai Dicari',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: match.isMutualMatch
                            ? AppColors.primaryPressed
                            : AppColors.barterText,
                      ),
                    ),
                  ),
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${listing.providerName} · ${listing.category}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Menawarkan: ${listing.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPressed,
                  ),
                ),
                if (listing.barterWant != null && listing.barterWant!.isNotEmpty)
                  Text(
                    'Mencari imbalan: ${listing.barterWant}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.barterText,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: selected ? AppColors.barter : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
