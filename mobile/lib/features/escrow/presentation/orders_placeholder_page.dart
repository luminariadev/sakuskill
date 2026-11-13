import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

// Warna diambil dari token tema tim (AppColors).
const _emerald = AppColors.primary;
const _emeraldSoft = AppColors.primarySurface;
const _blue = AppColors.escrow;
const _blueSoft = AppColors.escrowSurface;
const _ink = AppColors.textPrimary;
const _muted = AppColors.textSecondary;
const _faint = AppColors.textMuted;
const _line = AppColors.borderLight;
const _danger = AppColors.dispute;
const _grayBox = AppColors.canvasLight;

enum EscrowStage { ordered, funded, working, proof, done }

enum _Filter { all, active, done, disputed }

const _detailLabels = ['Dipesan', 'Dana aman', 'Dikerjakan', 'Bukti', 'Selesai'];
const _ledgerLabels = ['Funded', 'In Progress', 'Submitted', 'Released'];

class EscrowOrderView {
  EscrowOrderView({
    required this.code,
    required this.title,
    required this.provider,
    required this.major,
    required this.amount,
    required this.stage,
    this.proofUrl,
    this.proofNote,
    this.proofSent,
    this.disputed = false,
  });

  final String code;
  final String title;
  final String provider;
  final String major;
  final int amount;
  EscrowStage stage;
  final String? proofUrl;
  final String? proofNote;
  final String? proofSent;
  bool disputed;

  bool get isActive => !disputed && stage != EscrowStage.done;
}

String _rupiah(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp $buf';
}

// Validasi sementara. Ganti dengan url_sanitizer milik Anggota 6 bila siap.
bool _isHttps(String? url) {
  if (url == null) return false;
  final u = Uri.tryParse(url.trim());
  return u != null && u.scheme == 'https' && u.host.isNotEmpty;
}

String _shortUrl(String url) {
  final u = Uri.tryParse(url);
  if (u == null) return url;
  return '${u.host}${u.path}';
}

(String, Color) _statusOf(EscrowOrderView o) {
  if (o.disputed) return ('SENGKETA', _danger);
  switch (o.stage) {
    case EscrowStage.ordered:
      return ('MENUNGGU DANA', _muted);
    case EscrowStage.funded:
      return ('DANA AMAN', _blue);
    case EscrowStage.working:
    case EscrowStage.proof:
      return ('IN PROGRESS', _blue);
    case EscrowStage.done:
      return ('SELESAI', _emerald);
  }
}

// Posisi stepper 4 tahap di Escrow Ledger. Nilai 4 = semua selesai.
int _ledgerCurrent(EscrowStage s) {
  switch (s) {
    case EscrowStage.ordered:
      return 0;
    case EscrowStage.funded:
    case EscrowStage.working:
      return 1;
    case EscrowStage.proof:
      return 2;
    case EscrowStage.done:
      return 4;
  }
}

void _toast(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

// ---- Aksi bersama (dipakai halaman daftar dan halaman detail) ----

Future<bool> _releaseFlow(BuildContext context, EscrowOrderView o) async {
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => EscrowConfirmPage(order: o)),
  );
  if (ok == true) {
    o.stage = EscrowStage.done;
    return true;
  }
  return false;
}

Future<bool> _revisionFlow(BuildContext context, EscrowOrderView o) async {
  final ctl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final note = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Minta revisi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextFormField(
              controller: ctl,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Jelaskan bagian yang perlu diperbaiki',
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 10) ? 'Tulis minimal 10 karakter' : null,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _emerald),
                onPressed: () {
                  if (formKey.currentState!.validate()) Navigator.pop(ctx, ctl.text.trim());
                },
                child: const Text('Kirim permintaan revisi'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (note == null) return false;
  o.stage = EscrowStage.working;
  return true;
}

Future<bool> _disputeFlow(BuildContext context, EscrowOrderView o) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Laporkan masalah?'),
      content: const Text(
          'Dana tetap ditahan dan kasus diteruskan ke Komite Etik kampus untuk disidangkan.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Laporkan', style: TextStyle(color: _danger)),
        ),
      ],
    ),
  );
  if (yes != true) return false;
  // TODO: sambungkan ke layar Komite Etik bila sudah dibuat.
  o.disputed = true;
  return true;
}

// ---- Halaman Escrow Ledger (tab Orders) ----

class EscrowOrdersPage extends StatefulWidget {
  const EscrowOrdersPage({super.key});

  @override
  State<EscrowOrdersPage> createState() => _EscrowOrdersPageState();
}

class _EscrowOrdersPageState extends State<EscrowOrdersPage> {
  _Filter _filter = _Filter.active;

  // Data contoh. Ganti dengan repository milik Anggota 5 nanti.
  final List<EscrowOrderView> _orders = [
    EscrowOrderView(
      code: 'SK-2026-081',
      title: 'Desain Poster Dies Natalis',
      provider: 'Farhan Pratama',
      major: 'Informatika',
      amount: 50000,
      stage: EscrowStage.proof,
      proofUrl: 'https://drive.google.com/sakuskill/draft-poster.pdf',
      proofNote: 'Sudah disesuaikan dengan revisi warna emerald dan format siap cetak A3.',
      proofSent: 'Dikirim hari ini, 10.45 WIB',
    ),
    EscrowOrderView(
      code: 'SK-2026-080',
      title: 'Pembersihan Kipas, Heatsink & Ganti Thermal Paste Laptop',
      provider: 'Ahmad Fauzi',
      major: 'Teknik Informatika',
      amount: 45000,
      stage: EscrowStage.done,
      proofUrl: 'https://drive.google.com/laptop-repasta-proof.jpg',
    ),
  ];

  List<EscrowOrderView> get _visible => _orders.where((o) {
        switch (_filter) {
          case _Filter.all:
            return true;
          case _Filter.active:
            return o.isActive;
          case _Filter.done:
            return !o.disputed && o.stage == EscrowStage.done;
          case _Filter.disputed:
            return o.disputed;
        }
      }).toList();

  int get _activeCount => _orders.where((o) => o.isActive).length;

  int get _heldAmount => _orders
      .where((o) => o.stage != EscrowStage.done)
      .fold(0, (sum, o) => sum + o.amount);

  Future<void> _open(EscrowOrderView o) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EscrowDetailPage(order: o)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _release(EscrowOrderView o) async {
    if (await _releaseFlow(context, o) && mounted) {
      setState(() {});
      _toast(context, '${_rupiah(o.amount)} diteruskan ke ${o.provider}');
    }
  }

  Future<void> _revise(EscrowOrderView o) async {
    if (await _revisionFlow(context, o) && mounted) {
      setState(() {});
      _toast(context, 'Permintaan revisi dikirim ke ${o.provider}');
    }
  }

  Future<void> _dispute(EscrowOrderView o) async {
    if (await _disputeFlow(context, o) && mounted) {
      setState(() {});
      _toast(context, 'Masalah dilaporkan ke Komite Etik');
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Escrow Ledger',
                          style: TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w800, color: _ink)),
                      SizedBox(height: 2),
                      Text('Sistem Rekening Bersama Mahasiswa',
                          style: TextStyle(color: _muted, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.shield_outlined, color: _emerald, size: 28),
              ],
            ),
            const SizedBox(height: 16),
            _FilterTabs(
              filter: _filter,
              activeCount: _activeCount,
              onChanged: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _blueSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _blue.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline, color: _blue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dana sebesar ${_rupiah(_heldAmount)} disimpan di sistem penampungan. '
                      'Penyedia jasa baru menerima pembayaran setelah bukti disetujui.',
                      style: const TextStyle(color: _blue, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                    child: Text('Belum ada pesanan di kategori ini.',
                        style: TextStyle(color: _muted))),
              ),
            for (final o in list)
              _LedgerCard(
                order: o,
                onOpen: () => _open(o),
                onRelease: () => _release(o),
                onRevise: () => _revise(o),
                onDispute: () => _dispute(o),
              ),
            const SizedBox(height: 4),
            const Center(
              child: Text('Dilindungi escrow, disepakati bersama.',
                  style: TextStyle(color: _muted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs(
      {required this.filter, required this.activeCount, required this.onChanged});
  final _Filter filter;
  final int activeCount;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <(_Filter, String)>[
      (_Filter.all, 'Semua'),
      (_Filter.active, 'Aktif ($activeCount)'),
      (_Filter.done, 'Selesai'),
      (_Filter.disputed, 'Sengketa'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          for (final (f, label) in items)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onChanged(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: filter == f ? _emerald : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: filter == f ? Colors.white : _ink,
                      )),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.order);
  final EscrowOrderView order;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusOf(order);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({
    required this.order,
    required this.onOpen,
    required this.onRelease,
    required this.onRevise,
    required this.onDispute,
  });

  final EscrowOrderView order;
  final VoidCallback onOpen;
  final VoidCallback onRelease;
  final VoidCallback onRevise;
  final VoidCallback onDispute;

  @override
  Widget build(BuildContext context) {
    final o = order;
    final canDecide = o.stage == EscrowStage.proof && !o.disputed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onOpen,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${o.code}', style: const TextStyle(color: _muted, fontSize: 12)),
                    _StatusChip(o),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _emeraldSoft,
                      child: Text(o.provider[0],
                          style: const TextStyle(
                              color: _emerald, fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.provider,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                          Text(o.title,
                              style: const TextStyle(color: _muted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: _grayBox, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL TRANSAKSI',
                          style: TextStyle(
                              color: _muted, fontSize: 10, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(_rupiah(o.amount),
                          style: const TextStyle(
                              color: _emerald, fontSize: 28, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _StepTrack(
                  labels: _ledgerLabels,
                  current: _ledgerCurrent(o.stage),
                  activeColor: _blue,
                ),
                if (o.proofUrl != null) ...[
                  const SizedBox(height: 16),
                  _ProofBox(url: o.proofUrl!),
                ],
                const SizedBox(height: 14),
                if (canDecide) ...[
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: _emerald, minimumSize: const Size.fromHeight(48)),
                    onPressed: onRelease,
                    child: const Text('Setujui & Cairkan Dana'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: _ink, side: const BorderSide(color: _line)),
                        onPressed: onRevise,
                        child: const Text('Minta Revisi'),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: TextButton(
                          onPressed: onDispute,
                          child: const Text('Laporkan Masalah / Sidang Etik',
                              style: TextStyle(color: _danger, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    o.disputed
                        ? 'Kasus sedang ditinjau Komite Etik. Dana tetap ditahan.'
                        : o.stage == EscrowStage.done
                            ? 'Dana sudah diteruskan ke ${o.provider}.'
                            : 'Menunggu penyedia mengirim bukti pekerjaan.',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProofBox extends StatelessWidget {
  const _ProofBox({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final ok = _isHttps(url);
    return CustomPaint(
      painter: const _DashedBorderPainter(color: _line, radius: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _grayBox,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ok
                  ? 'BERKAS PENGERJAAN · HTTPS TERVERIFIKASI'
                  : 'BERKAS PENGERJAAN · TAUTAN DITOLAK (WAJIB HTTPS)',
              style: TextStyle(
                  color: ok ? _emerald : _danger,
                  fontSize: 10,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(_shortUrl(url),
                style: const TextStyle(
                    color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(url, style: const TextStyle(color: _faint, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
        d += 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

// Chip status di halaman Detail: huruf biasa dan biru, sesuai Figma.
class _DetailChip extends StatelessWidget {
  const _DetailChip(this.order);
  final EscrowOrderView order;

  @override
  Widget build(BuildContext context) {
    final o = order;
    final label = o.disputed
        ? 'Sengketa'
        : switch (o.stage) {
            EscrowStage.ordered => 'Menunggu dana',
            EscrowStage.funded => 'Dana aman',
            EscrowStage.working => 'Dikerjakan',
            EscrowStage.proof => 'Bukti dikirim',
            EscrowStage.done => 'Selesai',
          };
    final color = o.disputed ? _danger : _blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

// Isi kartu "Hasil pekerjaan" di Detail: nama berkas, folder, catatan, waktu.
class _DetailProof extends StatelessWidget {
  const _DetailProof({required this.order});
  final EscrowOrderView order;

  @override
  Widget build(BuildContext context) {
    final url = order.proofUrl!;
    final ok = _isHttps(url);
    final u = Uri.tryParse(url);
    final segs = (u?.pathSegments ?? const <String>[]).where((e) => e.isNotEmpty).toList();
    final file = segs.isEmpty ? url : segs.last;
    final parent = segs.length > 1 ? segs.sublist(0, segs.length - 1).join('/') : '';
    final dir = u == null ? '' : (parent.isEmpty ? '${u.host}/' : '${u.host}/$parent/');
    final pillColor = ok ? _emerald : _danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: pillColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(ok ? 'HTTPS terverifikasi' : 'Tautan ditolak (wajib https)',
              style: TextStyle(
                  color: pillColor, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.link, color: _emerald, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(file,
                      style: const TextStyle(
                          color: _emerald, fontSize: 14, fontWeight: FontWeight.w800)),
                  if (dir.isNotEmpty)
                    Text(dir, style: const TextStyle(color: _muted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        if (order.proofNote != null) ...[
          const SizedBox(height: 10),
          Text('\u201C${order.proofNote}\u201D',
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.4)),
        ],
        if (order.proofSent != null) ...[
          const SizedBox(height: 8),
          Text(order.proofSent!, style: const TextStyle(color: _faint, fontSize: 11)),
        ],
      ],
    );
  }
}

// Stepper bergaris. current == labels.length berarti semua tahap selesai.
class _StepTrack extends StatelessWidget {
  const _StepTrack({
    required this.labels,
    required this.current,
    required this.activeColor,
  });

  final List<String> labels;
  final int current;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < n; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                          height: 2,
                          color: i == 0
                              ? Colors.transparent
                              : (i <= current ? _emerald : _line)),
                    ),
                    _Dot(
                      done: i < current,
                      active: i == current,
                      number: i + 1,
                      activeColor: activeColor,
                    ),
                    Expanded(
                      child: Container(
                          height: 2,
                          color: i == n - 1
                              ? Colors.transparent
                              : (i < current ? _emerald : _line)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: i <= current ? _ink : _muted,
                      fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
                    )),
              ],
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.done,
    required this.active,
    required this.number,
    required this.activeColor,
  });

  final bool done;
  final bool active;
  final int number;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final color = done ? _emerald : (active ? activeColor : _line);
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: done
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : Text('$number',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : _muted)),
    );
  }
}

// ---- Halaman Detail pesanan ----

class EscrowDetailPage extends StatefulWidget {
  const EscrowDetailPage({super.key, required this.order});
  final EscrowOrderView order;

  @override
  State<EscrowDetailPage> createState() => _EscrowDetailPageState();
}

class _EscrowDetailPageState extends State<EscrowDetailPage> {
  EscrowOrderView get o => widget.order;

  Future<void> _release() async {
    if (await _releaseFlow(context, o) && mounted) {
      setState(() {});
      _toast(context, '${_rupiah(o.amount)} diteruskan ke ${o.provider}');
    }
  }

  Future<void> _revise() async {
    if (await _revisionFlow(context, o) && mounted) {
      setState(() {});
      _toast(context, 'Permintaan revisi dikirim ke ${o.provider}');
    }
  }

  Future<void> _dispute() async {
    if (await _disputeFlow(context, o) && mounted) {
      setState(() {});
      _toast(context, 'Masalah dilaporkan ke Komite Etik');
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = o.stage == EscrowStage.done;
    final canDecide = o.stage == EscrowStage.proof && !o.disputed;
    return Scaffold(
      appBar: AppBar(
          elevation: 0,
        foregroundColor: _ink,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detail pesanan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('ORDER #${o.code}', style: const TextStyle(fontSize: 11, color: _muted)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DetailChip(o),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _toast(context, 'Fitur chat belum tersambung'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: _emeraldSoft, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.chat_outlined, color: _emerald, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _line),
            ),
            child: _StepTrack(
              labels: _detailLabels,
              current: done ? _detailLabels.length : o.stage.index,
              activeColor: _emerald,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: _emeraldSoft, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.design_services, color: _emerald),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
                      const SizedBox(height: 2),
                      Text('${o.provider} · ${o.major}',
                          style: const TextStyle(color: _muted, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(_rupiah(o.amount),
                          style: const TextStyle(
                              color: _ink, fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (o.proofUrl != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _emerald),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    done ? 'Hasil disetujui · Dana dicairkan' : 'Hasil pekerjaan diserahkan',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
                  ),
                  const SizedBox(height: 8),
                  _DetailProof(order: o),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: o.disputed ? const Color(0xFFFEF2F2) : _emeraldSoft,
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(o.disputed ? Icons.gavel_outlined : Icons.verified_user_outlined,
                    color: o.disputed ? _danger : _emerald, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    o.disputed
                        ? 'Kasus sedang ditinjau Komite Etik. Dana tetap ditahan.'
                        : done
                            ? '${_rupiah(o.amount)} berhasil diteruskan ke ${o.provider}. Pesanan ini telah selesai.'
                            : 'Periksa hasilnya dahulu. Dana hanya cair setelah kamu menyetujui pekerjaan.',
                    style: TextStyle(
                        color: o.disputed ? _danger : _emerald, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (canDecide) ...[
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: _emerald, minimumSize: const Size.fromHeight(48)),
              onPressed: _release,
              child: Text('Setujui & lepas dana · ${_rupiah(o.amount)}'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: _ink, minimumSize: const Size.fromHeight(48)),
              onPressed: _revise,
              child: const Text('Minta revisi tambahan'),
            ),
            TextButton(
              onPressed: _dispute,
              child: const Text('Ajukan sengketa ke Komite Etik',
                  style: TextStyle(color: _danger)),
            ),
          ] else if (done) ...[
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: _emerald, minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kembali ke beranda'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: _ink, minimumSize: const Size.fromHeight(48)),
              onPressed: () => _toast(context, 'Fitur chat belum tersambung'),
              child: Text('Diskusikan hasil dengan ${o.provider.split(' ').first}'),
            ),
          ] else if (!o.disputed)
            const Text('Menunggu penyedia mengirim bukti pekerjaan.',
                textAlign: TextAlign.center, style: TextStyle(color: _muted)),
        ],
      ),
    );
  }
}

// ---- Layar konfirmasi pelepasan dana ----

class EscrowConfirmPage extends StatelessWidget {
  const EscrowConfirmPage({super.key, required this.order});
  final EscrowOrderView order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('KONFIRMASI ESCROW',
                  style: TextStyle(
                      color: _emerald, fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: _ink, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DANA YANG AKAN DILEPAS',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 8),
                    Text(_rupiah(order.amount),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('ke ${order.provider} · ${order.major}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text('Sudah sesuai\nharapanmu?',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, color: _ink, height: 1.2)),
              const SizedBox(height: 12),
              Text(
                'Dengan menyetujui, kamu mengonfirmasi hasil ${order.title} telah diterima dan dana boleh diteruskan ke penyedia.',
                style: const TextStyle(color: _muted, height: 1.5),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E0), borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  'Pastikan semua berkas bisa dibuka. Setelah disetujui, dana akan diteruskan ke penyedia.',
                  style: TextStyle(color: Color(0xFF9A3412), fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: _emerald, minimumSize: const Size.fromHeight(48)),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Ya, lepas ${_rupiah(order.amount)}'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: _ink, minimumSize: const Size.fromHeight(48)),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Kembali periksa hasil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pembungkus agar main_shell.dart tidak perlu diubah.
class OrdersPlaceholderPage extends StatelessWidget {
  const OrdersPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) => const EscrowOrdersPage();
}