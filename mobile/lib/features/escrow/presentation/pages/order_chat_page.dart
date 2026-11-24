import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/demo/demo_data.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_sheets.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../../core/widgets/saku_transaction.dart';
import '../../../auth/data/auth_session.dart';
import '../../data/datasources/escrow_remote_data_source.dart';
import '../../data/models/escrow_order_model.dart';

/// Figma "13 · Diskusi brief" — chat dengan draf kesepakatan tersemat.
class OrderChatPage extends StatefulWidget {
  const OrderChatPage({super.key, this.order});

  final EscrowOrderModel? order;

  @override
  State<OrderChatPage> createState() => _OrderChatPageState();
}

class _OrderChatPageState extends State<OrderChatPage> {
  EscrowOrderModel? _overrideOrder;
  bool _submittingProposal = false;
  bool _acceptingOrder = false;

  List<ChatMessage> _messages = const [];
  bool _loadingMessages = false;
  bool _sendingMessage = false;
  bool _initialized = false;
  Timer? _pollTimer;
  Timer? _clockTimer;
  String _liveClock = formatClockSeconds(DateTime.now());

  EscrowOrderModel? _resolveOrder(BuildContext context) {
    if (_overrideOrder != null) return _overrideOrder;
    if (widget.order != null) return widget.order;
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is EscrowOrderModel ? args : null;
  }

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _liveClock = formatClockSeconds(DateTime.now()));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final order = _resolveOrder(context);
    if (order != null && order.orderId.isNotEmpty) {
      _refreshOrderDetail(order.orderId);
      _loadMessages(order.orderId);
      _pollTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) {
          _loadMessages(order.orderId, silent: true);
          _refreshOrderDetail(order.orderId);
        },
      );
    } else {
      final now = DateTime.now();
      _messages = [
        ChatMessage(
          text: 'Halo Mbak Salma, spanduk kateringnya ukuran 3×1 m ya. '
              'Foto ayam bakarnya sudah saya lampirkan.',
          time: formatTimeWib(now.subtract(const Duration(minutes: 8))),
        ),
        ChatMessage(
          text: 'Halo Pak Dimas! Siap, materi sudah saya terima. Saya kerjakan '
              'format CMYK siap cetak selesai dalam 3 hari dengan tarif Rp 50.000.',
          time: formatTimeWib(now.subtract(const Duration(minutes: 5))),
          mine: true,
        ),
        ChatMessage(
          text: 'Baik Mbak, saya setuju. Saya langsung proses pembayarannya ya.',
          time: formatTimeWib(now.subtract(const Duration(minutes: 2))),
        ),
      ];
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  String? _resolveCurrentUserId(EscrowOrderModel? order) {
    final sessionId = AuthSession.instance.userId?.trim();
    if (sessionId != null && sessionId.isNotEmpty) return sessionId;

    if (order != null) {
      final opponentRole = (order.peranLawanTransaksi ?? '').toLowerCase();
      if (opponentRole.contains('penyedia') &&
          (order.pelangganId?.isNotEmpty ?? false)) {
        return order.pelangganId!.trim();
      }
      if (opponentRole.contains('pelanggan') &&
          (order.penyediaId?.isNotEmpty ?? false)) {
        return order.penyediaId!.trim();
      }
    }
    return null;
  }

  ChatMessage _mapJsonToChatMessage(
    Map<String, dynamic> json,
    String? currentUserId,
  ) {
    final senderId =
        (json['sender_id'] ?? json['pengirim_id'])?.toString().trim() ?? '';
    final rawTime = (json['dibuat_pada'] ?? json['created_at'])?.toString();
    final dt = rawTime != null ? DateTime.tryParse(rawTime)?.toLocal() : null;
    final timeStr = dt != null ? formatTimeWib(dt) : formatTimeWib(DateTime.now());

    return ChatMessage(
      text: (json['isi_pesan'] ?? json['pesan'])?.toString() ?? '',
      time: timeStr,
      mine: currentUserId != null &&
          currentUserId.isNotEmpty &&
          senderId.toLowerCase() == currentUserId.toLowerCase(),
    );
  }

  bool _isProviderRole(EscrowOrderModel? order) {
    if (order == null) return false;
    final myId = _resolveCurrentUserId(order);
    if (order.penyediaId != null &&
        order.penyediaId!.isNotEmpty &&
        myId != null &&
        myId.isNotEmpty) {
      return order.penyediaId!.toLowerCase() == myId.toLowerCase();
    }
    return (order.peranLawanTransaksi ?? '').toLowerCase().contains('pelanggan');
  }

  Future<void> _refreshOrderDetail(String orderId) async {
    try {
      final res =
          await AppScope.of(context).escrowRepository.fetchOrderDetail(orderId);
      if (!mounted || res.isFallback) return;
      setState(() => _overrideOrder = res.data);
    } catch (_) {}
  }

  Future<void> _acceptOrderFromChat(EscrowOrderModel currentOrder) async {
    if (_acceptingOrder || currentOrder.orderId.isEmpty) return;
    setState(() => _acceptingOrder = true);
    SakuMotion.tick();
    try {
      final res = await AppScope.of(context)
          .escrowRepository
          .acceptOrder(currentOrder.orderId);
      if (!mounted) return;
      setState(() => _overrideOrder = res.data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Pesanan disetujui! Klien kini dapat melakukan pembayaran ke Escrow.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } on EscrowException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyetujui pesanan: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _acceptingOrder = false);
    }
  }

  Future<void> _loadMessages(String orderId, {bool silent = false}) async {
    if (!silent && mounted) setState(() => _loadingMessages = true);
    try {
      final repo = AppScope.of(context).escrowRepository;
      final res = await repo.fetchOrderMessages(orderId);
      if (!mounted) return;
      final myId = _resolveCurrentUserId(_resolveOrder(context));

      setState(() {
        _messages = res.data.map((e) => _mapJsonToChatMessage(e, myId)).toList();
      });
    } catch (_) {
      // Abaikan error saat background polling
    } finally {
      if (!silent && mounted) setState(() => _loadingMessages = false);
    }
  }

  Future<bool> _handleSendMessage(
    String text,
    EscrowOrderModel? currentOrder,
  ) async {
    if (currentOrder == null || currentOrder.orderId.isEmpty) {
      final now = DateTime.now();
      setState(() {
        _messages = [
          ..._messages,
          ChatMessage(
            text: text,
            time: formatTimeWib(now),
            mine: true,
          ),
        ];
      });
      return true;
    }

    setState(() => _sendingMessage = true);
    try {
      final repo = AppScope.of(context).escrowRepository;
      final res = await repo.sendOrderMessage(
        orderId: currentOrder.orderId,
        isiPesan: text,
      );
      if (!mounted) return false;
      final myId = _resolveCurrentUserId(currentOrder);
      setState(() {
        _messages = [..._messages, _mapJsonToChatMessage(res.data, myId)];
      });
      return true;
    } on EscrowException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return false;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim pesan: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return false;
    } finally {
      if (mounted) setState(() => _sendingMessage = false);
    }
  }

  /// POST /api/v1/orders/:id/proposals (Negosiasi scope, harga, atau tenggat)
  Future<void> _openProposalSheet(EscrowOrderModel currentOrder) async {
    if (_submittingProposal) return;

    final draft = await showSakuSheet<_ProposalDraft>(
      context,
      builder: (_) => _ProposalSheet(order: currentOrder),
    );

    if (draft == null || !mounted) return;

    if (currentOrder.orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode demo: Proposal negosiasi diperbarui secara lokal.'),
        ),
      );
      return;
    }

    setState(() => _submittingProposal = true);
    final repo = AppScope.of(context).escrowRepository;

    try {
      final result = await repo.submitProposal(
        orderId: currentOrder.orderId,
        deskripsiRuangLingkup: draft.scope,
        hargaTawaran: draft.price,
        tenggatUsulan: DateTime.now().toUtc().add(Duration(days: draft.days)),
      );

      if (!mounted) return;
      setState(() => _overrideOrder = result.data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Proposal perubahan kesepakatan berhasil dikirim! Menunggu persetujuan penyedia.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } on EscrowException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim proposal: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submittingProposal = false);
    }
  }

  Future<void> _proceedToPayment(EscrowOrderModel? currentOrder) async {
    SakuMotion.tick();

    // Cek sinkronisasi status terbaru dari backend jika memiliki orderId asli
    if (currentOrder != null && currentOrder.orderId.isNotEmpty) {
      final repo = AppScope.of(context).escrowRepository;
      final latestRes = await repo.fetchOrderDetail(currentOrder.orderId);
      final latestOrder = latestRes.isFallback ? currentOrder : latestRes.data;

      if (!mounted) return;

      // Sesuai kontrak API v1.3: Pembayaran hanya bisa dilakukan jika status = accepted
      if (!latestRes.isFallback && latestOrder.statusKode != 'accepted') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pesanan berstatus "${latestOrder.statusPesanan}". '
              'Penyedia jasa harus menyetujui kesepakatan terlebih dahulu sebelum pembayaran.',
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        return;
      }

      Navigator.of(context).pushNamed(
        AppRoutes.payment,
        arguments: latestOrder,
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.payment,
      arguments: currentOrder,
    );
  }

  Widget _buildAgreementActions(EscrowOrderModel? currentOrder) {
    if (currentOrder == null || currentOrder.orderId.isEmpty) {
      return SakuButton(
        key: const Key('chat-agree'),
        label: 'Setujui & Lanjut Pembayaran Escrow',
        onPressed: () => _proceedToPayment(currentOrder),
      );
    }

    final isProvider = _isProviderRole(currentOrder);
    final status = currentOrder.statusKode.toLowerCase();

    if (status == 'requested' ||
        status == 'submitted' ||
        status == 'diajukan' ||
        status == 'negotiating') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (isProvider)
            SakuButton(
              key: const Key('chat-provider-accept'),
              label: _acceptingOrder
                  ? 'Menyetujui Pesanan...'
                  : 'Terima & Sepakati Pesanan',
              onPressed: _acceptingOrder
                  ? null
                  : () => _acceptOrderFromChat(currentOrder),
            )
          else
            const InfoBox(
              text:
                  'Menunggu penyedia jasa menyetujui pesanan sebelum pembayaran escrow dibuka.',
              tone: SakuTone.neutral,
              fontWeight: FontWeight.w500,
            ),
          OutlinedButton(
            onPressed: _submittingProposal
                ? null
                : () => _openProposalSheet(currentOrder),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
            ),
            child: Text(
              _submittingProposal
                  ? 'Mengirim Proposal...'
                  : 'Ajukan Penyesuaian Harga / Tenggat',
            ),
          ),
        ],
      );
    }

    if (status == 'accepted' || status == 'disepakati') {
      if (isProvider) {
        return const InfoBox(
          text:
              'Pesanan sudah disepakati! Menunggu pelanggan membayar & mengunci dana ke Rekening Bersama Escrow.',
          tone: SakuTone.escrow,
          fontWeight: FontWeight.w500,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          SakuButton(
            key: const Key('chat-agree'),
            label: 'Bayar & Kunci Dana di Escrow',
            onPressed: () => _proceedToPayment(currentOrder),
          ),
          OutlinedButton(
            onPressed: _submittingProposal
                ? null
                : () => _openProposalSheet(currentOrder),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
            ),
            child: Text(
              _submittingProposal
                  ? 'Mengirim Proposal...'
                  : 'Ajukan Penyesuaian Harga / Tenggat',
            ),
          ),
        ],
      );
    }

    if (status == 'completed' || status == 'selesai') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          const InfoBox(
            text:
                'Pesanan telah selesai & dana simulasi telah diteruskan ke penyedia jasa.',
            tone: SakuTone.success,
            fontWeight: FontWeight.w500,
          ),
          SakuButton(
            label: isProvider ? 'Lihat Ringkasan Pesanan' : 'Lihat Ringkasan & Ulasan',
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.orderDone,
              arguments: currentOrder,
            ),
          ),
        ],
      );
    }

    if (status == 'rejected' ||
        status == 'cancelled' ||
        status == 'dibatalkan' ||
        status == 'ditolak') {
      return InfoBox(
        text: 'Pesanan berstatus "${currentOrder.statusPesanan}".',
        tone: SakuTone.danger,
        fontWeight: FontWeight.w500,
      );
    }

    final targetRoute = isProvider
        ? AppRoutes.workroom
        : (status == 'awaiting_review'
            ? AppRoutes.reviewWork
            : AppRoutes.tracking);
    final label = isProvider
        ? 'Buka Ruang Kerja Penyedia'
        : (status == 'awaiting_review'
            ? 'Periksa Hasil Pekerjaan'
            : 'Pantau Progres Pesanan');

    return SakuButton(
      label: label,
      onPressed: () => Navigator.of(context)
          .pushNamed(targetRoute, arguments: currentOrder),
    );
  }

  @override
  Widget build(BuildContext context) {
    const demo = DemoData.order;
    final currentOrder = _resolveOrder(context);

    final providerName = currentOrder?.namaLawanTransaksi ?? demo.provider;
    final serviceTitle = currentOrder?.judulLayanan ?? 'Spanduk 3×1 m';
    final amount = currentOrder?.harga ?? demo.amount;
    final deadlineDays = currentOrder?.detikTersisa != null
        ? (currentOrder!.detikTersisa! / 86400).ceil().clamp(1, 365)
        : demo.deadlineDays;

    return SakuScreen(
      background: AppColors.canvasLight,
      showBack: true,
      children: [
        PageHeader(providerName),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Online · Sinkronisasi Realtime $_liveClock',
              style: const TextStyle(
                fontSize: 11,
                height: 15 / 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        InfoBox(
          tone: SakuTone.escrow,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DRAFT KESEPAKATAN',
                    style: TextStyle(
                      fontSize: 10,
                      height: 14 / 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.escrowText,
                    ),
                  ),
                  if (currentOrder != null)
                    Text(
                      currentOrder.statusPesanan.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
              Text(
                '$serviceTitle · Harga: ${formatRupiah(amount)}\n'
                'Tenggat: $deadlineDays Hari',
                style: const TextStyle(
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              _buildAgreementActions(currentOrder),
            ],
          ),
        ),
        if (_loadingMessages && _messages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          if (currentOrder != null &&
              currentOrder.orderId.isNotEmpty &&
              _messages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Belum ada pesan. Mulai diskusi brief, detail pekerjaan, atau tenggat di bawah.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ChatThread(
            initial: _messages,
            messages: _messages,
            sending: _sendingMessage,
            onSendMessage: (text) => _handleSendMessage(text, currentOrder),
          ),
        ],
      ],
    );
  }
}

class _ProposalDraft {
  const _ProposalDraft({
    required this.scope,
    required this.price,
    required this.days,
  });

  final String scope;
  final int price;
  final int days;
}

class _ProposalSheet extends StatefulWidget {
  const _ProposalSheet({required this.order});

  final EscrowOrderModel order;

  @override
  State<_ProposalSheet> createState() => _ProposalSheetState();
}

class _ProposalSheetState extends State<_ProposalSheet> {
  late final TextEditingController _scopeCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _daysCtrl;

  @override
  void initState() {
    super.initState();
    _scopeCtrl = TextEditingController(
      text: widget.order.deskripsiBrief ?? widget.order.judulLayanan,
    );
    _priceCtrl = TextEditingController(text: widget.order.harga.toString());
    final initialDays = widget.order.detikTersisa != null
        ? (widget.order.detikTersisa! / 86400).ceil().clamp(1, 365)
        : 3;
    _daysCtrl = TextEditingController(text: initialDays.toString());
  }

  @override
  void dispose() {
    _scopeCtrl.dispose();
    _priceCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SakuSheetContent(
      title: 'Ajukan Penyesuaian Kesepakatan',
      message: 'Usulkan perubahan ruang lingkup, harga tawaran, atau tenggat waktu:',
      body: [
        SakuTextField(
          controller: _scopeCtrl,
          label: 'Deskripsi Ruang Lingkup (Min. 10 Karakter)',
          minLines: 2,
          maxLines: 4,
        ),
        SakuTextField(
          controller: _priceCtrl,
          label: 'Harga Tawaran (Rp)',
          keyboardType: TextInputType.number,
        ),
        SakuTextField(
          controller: _daysCtrl,
          label: 'Usulan Tenggat (Hari)',
          keyboardType: TextInputType.number,
        ),
      ],
      confirmLabel: 'Kirim Proposal',
      cancelLabel: 'Batal',
      onConfirm: () {
        final scope = _scopeCtrl.text.trim();
        final price = int.tryParse(_priceCtrl.text.trim()) ?? widget.order.harga;
        final days = int.tryParse(_daysCtrl.text.trim()) ?? 3;
        Navigator.of(context).pop(
          _ProposalDraft(
            scope: scope.length >= 10 ? scope : '$scope (Penyesuaian brief)',
            price: price > 0 ? price : widget.order.harga,
            days: days > 0 ? days : 1,
          ),
        );
      },
    );
  }
}