import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/state/account_finance_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';
import '../../../activity/presentation/pages/activity_page.dart';

/// Figma "25 · Dompet SakuSkill" — desain claymorphism & glassmorphism
/// tersinkron penuh dengan [AccountFinanceStore].
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  int? _destination;
  int _channelIndex = 0;
  final _amountCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  bool _synced = false;

  static const _methods = ['Transfer Bank', 'E-Wallet'];
  static const _bankChannels = ['BCA', 'Mandiri', 'BRI', 'BNI'];
  static const _ewalletChannels = ['GoPay', 'DANA', 'OVO', 'ShopeePay'];
  static const _quickAmounts = [25000, 50000, 100000];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_synced) {
      _synced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AccountFinanceStore.instance.refreshLive(
          escrowRepository: AppScope.of(context).escrowRepository,
        );
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    super.dispose();
  }

  void _fillMaxAmount(int availableBalance) {
    if (availableBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Saldo pendapatan Anda masih Rp 0. Selesaikan pesanan sebagai penyedia jasa terlebih dahulu.',
          ),
        ),
      );
      return;
    }
    SakuMotion.tick();
    setState(() => _amountCtrl.text = availableBalance.toString());
  }

  void _submitWithdraw(int availableBalance) {
    if (_destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tujuan penarikan terlebih dahulu.'),
        ),
      );
      return;
    }

    final parsedAmount =
        int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final channels = _destination == 1 ? _ewalletChannels : _bankChannels;
    final channel = channels[_channelIndex.clamp(0, channels.length - 1)];
    final methodLabel = '${_methods[_destination!]} ($channel)';
    final error = AccountFinanceStore.instance.simulateWithdraw(
      amount: parsedAmount,
      methodLabel: methodLabel,
      destinationAccount: _accountCtrl.text,
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
      );
      return;
    }

    _amountCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Simulasi penarikan ${formatRupiah(parsedAmount)} ke $methodLabel (${_accountCtrl.text.trim()}) dicatat.',
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AccountFinanceStore.instance,
      builder: (context, _) {
        final store = AccountFinanceStore.instance;
        final available = store.availableBalance;
        final escrowHeld = store.escrowHeld;
        final activeOrders = store.activeOrderCount;
        final mutations = store.mutations;
        final channels = _destination == 1 ? _ewalletChannels : _bankChannels;

        return SakuScreen(
          background: AppColors.canvasLight,
          showBack: true,
          gap: 16,
          children: [
            const PageHeader(
              'Dompet SakuSkill',
              subtitle: 'Pantau saldo pendapatan, escrow, dan penarikan dana',
            ),
            _WalletHeroCard(
              available: available,
              escrowHeld: escrowHeld,
              activeOrders: activeOrders,
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.escrowSurface.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: AppColors.escrowText,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Simulasi Dompet MVP: mutasi & penarikan tercatat secara internal untuk menguji alur keuangan transaksi.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 17 / 12,
                            color: AppColors.escrowText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SectionLabel('PILIH TUJUAN PENARIKAN'),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _MethodTile(
                      icon: Icons.account_balance_rounded,
                      title: 'Transfer Bank',
                      subtitle: 'BCA · Mandiri · BRI · BNI',
                      selected: _destination == 0,
                      onTap: () {
                        SakuMotion.tick();
                        setState(() {
                          _destination = 0;
                          _channelIndex = 0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MethodTile(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'E-Wallet',
                      subtitle: 'GoPay · DANA · OVO · ShopeePay',
                      selected: _destination == 1,
                      onTap: () {
                        SakuMotion.tick();
                        setState(() {
                          _destination = 1;
                          _channelIndex = 0;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_destination != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Row(
                  key: ValueKey('channels-$_destination'),
                  children: [
                    for (var i = 0; i < channels.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _ChannelPill(
                          label: channels[i],
                          selected: _channelIndex == i,
                          onTap: () {
                            SakuMotion.tick();
                            setState(() => _channelIndex = i);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            SakuCard(
              radius: 22,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 14,
                children: [
                  const SectionLabel('FORMULIR PENARIKAN'),
                  SakuTextField(
                    key: const Key('wallet-account-input'),
                    controller: _accountCtrl,
                    label: _destination == 1
                        ? 'Nomor HP E-Wallet Tujuan'
                        : 'Nomor Rekening Tujuan',
                    hint: _destination == 1
                        ? 'Contoh: 081234567890'
                        : 'Contoh: 1310012345678',
                    keyboardType: TextInputType.number,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 10,
                    children: [
                      Expanded(
                        child: SakuTextField(
                          key: const Key('wallet-amount-input'),
                          controller: _amountCtrl,
                          label: 'Nominal Penarikan (Rp)',
                          hint: 'Contoh: 50000',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: SakuButton(
                          key: const Key('wallet-fill-max'),
                          label: 'Tarik Semua',
                          variant: SakuButtonVariant.outline,
                          expand: false,
                          height: 46,
                          fontSize: 12,
                          onPressed: () => _fillMaxAmount(available),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final preset in _quickAmounts)
                        ActionChip(
                          label: Text(
                            formatRupiah(preset),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryPressed,
                            ),
                          ),
                          backgroundColor: AppColors.primarySurface,
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                          onPressed: () {
                            SakuMotion.tick();
                            setState(() => _amountCtrl.text = '$preset');
                          },
                        ),
                    ],
                  ),
                  SakuButton(
                    key: const Key('wallet-withdraw'),
                    label: 'Tarik Saldo ke Rekening / E-Wallet',
                    onPressed: () => _submitWithdraw(available),
                  ),
                ],
              ),
            ),
            const SectionLabel('RIWAYAT MUTASI DOMPET'),
            if (mutations.isEmpty)
              const SakuCard(
                radius: 20,
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClayIconBadge(
                      size: 44,
                      radius: 14,
                      tint: AppColors.primary,
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Belum ada mutasi dompet. Catatan pemasukan & penarikan otomatis muncul setelah transaksi selesai.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 18 / 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SakuCard(
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 14,
                  children: [
                    for (var i = 0; i < mutations.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _LedgerRow(
                        title: mutations[i].title,
                        amount: mutations[i].amountLabel,
                        note: mutations[i].note,
                        incoming: mutations[i].incoming,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WalletHeroCard extends StatelessWidget {
  const _WalletHeroCard({
    required this.available,
    required this.escrowHeld,
    required this.activeOrders,
  });

  final int available;
  final int escrowHeld;
  final int activeOrders;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A241A),
            Color(0xFF0F3D2C),
            Color(0xFF0A2A1E),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppShadows.clayElevated,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -34,
              top: -34,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryLight.withValues(alpha: 0.35),
                      AppColors.primaryLight.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 14,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SALDO PENDAPATAN SIAP TARIK',
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          borderRadius: AppRadius.pillBr,
                          border: Border.all(
                            color: AppColors.primaryLight.withValues(alpha: 0.45),
                          ),
                        ),
                        child: const Text(
                          'TERPROTEKSI',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7DF0C0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  CountUpRupiah(
                    value: available,
                    style: const TextStyle(
                      fontSize: 34,
                      height: 44 / 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroMetricTile(
                          label: 'Dana Ditahan Escrow',
                          value: formatRupiah(escrowHeld),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeroMetricTile(
                          label: 'Transaksi Aktif',
                          value: '$activeOrders Order',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetricTile extends StatelessWidget {
  const _HeroMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFFA7C6B9),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: selected
                ? const [Color(0xFFE7F9F1), Color(0xFFD5F3E5)]
                : const [AppColors.clayTop, Color(0xFFF6FAF8)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.white,
            width: 1.5,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 8,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClayIconBadge(
                  size: 36,
                  radius: 11,
                  tint: AppColors.primary,
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    key: ValueKey(selected),
                    size: 20,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 15 / 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelPill extends StatelessWidget {
  const _ChannelPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.clayBorder,
              width: 1.2,
            ),
            boxShadow: selected ? AppShadows.card : AppShadows.flat,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
              child: Text(label, maxLines: 1),
            ),
          ),
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.title,
    required this.amount,
    required this.note,
    this.incoming = false,
  });

  final String title;
  final String amount;
  final String note;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    final tint = incoming ? AppColors.primary : AppColors.textPrimary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClayIconBadge(
          size: 38,
          radius: 12,
          tint: incoming ? AppColors.primary : AppColors.escrow,
          child: Icon(
            incoming ? Icons.south_west_rounded : Icons.north_east_rounded,
            size: 18,
            color: incoming ? AppColors.primary : AppColors.escrowText,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 3,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: tint,
                    ),
                  ),
                ],
              ),
              Text(
                note,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 16 / 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
