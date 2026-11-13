import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';

// Warna utama Barter diambil dari tema tim. Widget yang memakainya sengaja
// tidak di-const, supaya aman walau AppColors.barter bukan konstanta.
final _purple = AppColors.barter;
final _purpleSoft = _purple.withValues(alpha: 0.1);
final _purpleBox = _purple.withValues(alpha: 0.06);

const _ok = Color(0xFF059669);
const _warn = Color(0xFFB45309);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFE2E8F0);
const _bg = Color(0xFFF8FAFC);
const _grayBox = Color(0xFFF1F5F9);

enum Deliverable { notStarted, working, delivered }

class BarterContractView {
  BarterContractView({
    required this.code,
    required this.giveTitle,
    required this.giveStatus,
    required this.getTitle,
    required this.partnerLabel,
    required this.getStatus,
    required this.deadline,
    this.myApproved = false,
    this.partnerApproved = false,
  });

  final String code;
  final String giveTitle;
  Deliverable giveStatus;
  final String getTitle;
  final String partnerLabel;
  Deliverable getStatus;
  final String deadline;
  bool myApproved;
  bool partnerApproved;

  bool get completed => myApproved && partnerApproved;
}

const _months = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

class BarterHubPage extends StatefulWidget {
  const BarterHubPage({super.key});

  @override
  State<BarterHubPage> createState() => _BarterHubPageState();
}

class _BarterHubPageState extends State<BarterHubPage> {
  // Data contoh. Ganti dengan repository milik Anggota 5 nanti.
  final List<BarterContractView> _contracts = [
    BarterContractView(
      code: 'BTR-012',
      giveTitle: 'Slicing UI Flutter (2 Halaman)',
      giveStatus: Deliverable.delivered,
      getTitle: 'Editing Video Teaser Reels 30 Detik',
      partnerLabel: 'Zikri · DKV',
      getStatus: Deliverable.working,
      deadline: '14 November 2026',
      myApproved: true,
    ),
  ];

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _openPartnerSheet(BarterContractView c) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Berkas ${c.partnerLabel.split(' · ').first}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _deliverablePill(c.getStatus),
            const SizedBox(height: 8),
            Text(
              c.getStatus == Deliverable.delivered
                  ? 'Mitra sudah mengunggah hasil. Periksa dulu sebelum menyetujui.'
                  : 'Mitra belum mengunggah berkas.',
              style: const TextStyle(color: _muted),
            ),
            const SizedBox(height: 12),
            if (c.getStatus == Deliverable.delivered && !c.myApproved)
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: _ok, minimumSize: const Size.fromHeight(46)),
                onPressed: () => Navigator.pop(ctx, 'approve'),
                child: const Text('Setujui hasil mitra'),
              ),
            TextButton(
                style: TextButton.styleFrom(foregroundColor: _purple),
                onPressed: () => Navigator.pop(ctx, 'chat'),
                child: const Text('Buka chat diskusi')),
            TextButton(
                style: TextButton.styleFrom(foregroundColor: _purple),
                onPressed: () => Navigator.pop(ctx, 'mediate'),
                child: const Text('Minta bantuan mediasi')),
            // Tombol demo untuk mencoba alur. Hapus sebelum rilis.
            if (c.getStatus != Deliverable.delivered)
              TextButton(
                  style: TextButton.styleFrom(foregroundColor: _purple),
                  onPressed: () => Navigator.pop(ctx, 'demo_upload'),
                  child: const Text('Demo: mitra mengunggah berkas')),
            if (c.getStatus == Deliverable.delivered && !c.partnerApproved)
              TextButton(
                  style: TextButton.styleFrom(foregroundColor: _purple),
                  onPressed: () => Navigator.pop(ctx, 'demo_approve'),
                  child: const Text('Demo: mitra menyetujui hasilmu')),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'approve':
        setState(() => c.myApproved = true);
        _toast('Persetujuanmu tercatat');
      case 'chat':
        _toast('Chat belum tersambung');
      case 'mediate':
        _mediation();
      case 'demo_upload':
        setState(() => c.getStatus = Deliverable.delivered);
      case 'demo_approve':
        setState(() => c.partnerApproved = true);
    }
  }

  void _mediation() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Minta bantuan mediasi?'),
        content: const Text(
            'Permintaan diteruskan ke mediator kampus. Kedua pihak akan dihubungi untuk membahas kendala.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _toast('Permintaan mediasi dikirim');
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  Future<void> _newOffer() async {
    final formKey = GlobalKey<FormState>();
    final give = TextEditingController();
    final want = TextEditingController();
    var days = 7;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Buat tawaran barter baru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: give,
                  decoration: const InputDecoration(
                      labelText: 'Keahlian yang kamu berikan',
                      border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().length < 5) ? 'Tulis minimal 5 karakter' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: want,
                  decoration: const InputDecoration(
                      labelText: 'Keahlian yang kamu butuhkan',
                      border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.trim().length < 5) return 'Tulis minimal 5 karakter';
                    if (v.trim().toLowerCase() == give.text.trim().toLowerCase()) {
                      return 'Harus berbeda dari keahlian yang kamu berikan';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: days,
                  decoration: const InputDecoration(
                      labelText: 'Batas waktu', border: OutlineInputBorder()),
                  items: const [3, 7, 14]
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e hari')))
                      .toList(),
                  onChanged: (v) => setSheet(() => days = v ?? 7),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: _purple, minimumSize: const Size.fromHeight(48)),
                    onPressed: () {
                      if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
                    },
                    child: const Text('Buat tawaran'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (created == true && mounted) {
      setState(() {
        _contracts.insert(
          0,
          BarterContractView(
            code: 'BTR-${(12 + _contracts.length).toString().padLeft(3, '0')}',
            giveTitle: give.text.trim(),
            giveStatus: Deliverable.notStarted,
            getTitle: want.text.trim(),
            partnerLabel: 'Menunggu mitra',
            getStatus: Deliverable.notStarted,
            deadline: _fmt(DateTime.now().add(Duration(days: days))),
          ),
        );
      });
      _toast('Tawaran dibuat. Menunggu mitra.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            const Text('Smart Barter Hub',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 4),
            const Text('Pertukaran Keahlian Bilateral Antar-Mahasiswa\n(Tanpa Uang Tunai)',
                style: TextStyle(color: _muted, fontSize: 13, height: 1.4)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: _Pill(
                  label: '0% Potongan Biaya • Nilai Adil Mahasiswa',
                  color: _purple,
                  fontSize: 12),
            ),
            const SizedBox(height: 16),
            for (final c in _contracts)
              _ContractCard(contract: c, onOpenPartner: () => _openPartnerSheet(c)),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _purple,
                minimumSize: const Size.fromHeight(50),
                side: BorderSide(color: _purple.withValues(alpha: 0.5)),
              ),
              onPressed: _newOffer,
              icon: const Icon(Icons.add),
              label: const Text('Buat Tawaran Barter Baru'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _deliverablePill(Deliverable d) {
  switch (d) {
    case Deliverable.delivered:
      return const _Pill(label: '✓ Bukti Terkirim', color: _ok);
    case Deliverable.working:
      return const _Pill(label: 'Sedang Dikerjakan', color: _warn);
    case Deliverable.notStarted:
      return const _Pill(label: 'Belum dimulai', color: _muted);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.dot = false, this.fontSize = 11});
  final String label;
  final Color color;
  final bool dot;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(label,
                style: TextStyle(
                    color: color, fontSize: fontSize, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.contract, required this.onOpenPartner});
  final BarterContractView contract;
  final VoidCallback onOpenPartner;

  @override
  Widget build(BuildContext context) {
    final c = contract;
    final partnerText = c.partnerApproved
        ? '✓ Approved'
        : (c.getStatus == Deliverable.delivered ? 'Awaiting Approval' : 'Awaiting Upload');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('KONTRAK BARTER AKTIF',
                  style: TextStyle(
                      color: _muted, fontSize: 10, fontWeight: FontWeight.w700)),
              _Pill(
                  label: c.completed ? 'Selesai' : 'Live',
                  color: _ok,
                  dot: !c.completed),
            ],
          ),
          const SizedBox(height: 10),
          Text('#${c.code}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _DealBox(
                    label: 'ANDA MEMBERIKAN',
                    icon: Icons.code_rounded,
                    title: c.giveTitle,
                    background: _grayBox,
                    status: _deliverablePill(c.giveStatus),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DealBox(
                    label: 'DITERIMA DARI MITRA',
                    icon: Icons.play_arrow_rounded,
                    title: c.getTitle,
                    subtitle: c.partnerLabel,
                    background: _purpleBox,
                    status: _deliverablePill(c.getStatus),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: _purpleSoft, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, size: 14, color: _purple),
                  const SizedBox(width: 6),
                  Text('Pertukaran setara',
                      style: TextStyle(
                          color: _purple, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
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
                Text('Batas Waktu: ${c.deadline}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 4),
                const Text('Validasi bilateral ganda diperlukan sebelum status selesai.',
                    style: TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ApprovalRow(
              label: 'Anda',
              text: c.myApproved ? '✓ Approved' : 'Belum disetujui',
              color: c.myApproved ? _ok : _warn),
          const SizedBox(height: 6),
          _ApprovalRow(
              label: 'Mitra',
              text: partnerText,
              color: c.partnerApproved ? _ok : _warn),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: _purple, minimumSize: const Size.fromHeight(48)),
            onPressed: onOpenPartner,
            child: const Text('Lihat Berkas Mitra & Chat Diskusi'),
          ),
        ],
      ),
    );
  }
}

class _DealBox extends StatelessWidget {
  const _DealBox({
    required this.label,
    required this.icon,
    required this.title,
    required this.background,
    required this.status,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color background;
  final Widget status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: _muted, fontSize: 9, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Icon(icon, color: _purple, size: 26),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: _ink, fontSize: 13, height: 1.3)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(color: _muted, fontSize: 11)),
          ],
          const Spacer(),
          const SizedBox(height: 8),
          status,
        ],
      ),
    );
  }
}

class _ApprovalRow extends StatelessWidget {
  const _ApprovalRow({required this.label, required this.text, required this.color});
  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
        Text(text,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// Pembungkus agar main_shell.dart tidak perlu diubah.
class BarterPlaceholderPage extends StatelessWidget {
  const BarterPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) => const BarterHubPage();
}