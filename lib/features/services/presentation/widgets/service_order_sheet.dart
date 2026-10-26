import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/service_item.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/app_state_provider.dart';

class ServiceOrderSheet extends StatefulWidget {
  final ServiceItem service;
  final UserEntity provider;
  final AppStateProvider appState;

  const ServiceOrderSheet({
    super.key,
    required this.service,
    required this.provider,
    required this.appState,
  });

  @override
  State<ServiceOrderSheet> createState() => _ServiceOrderSheetState();
}

class _ServiceOrderSheetState extends State<ServiceOrderSheet> {
  final _notesController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleOrder() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = widget.appState.createEscrowOrder(
      service: widget.service,
      notes: _notesController.text,
    );

    if (error != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dana berhasil dikunci di Escrow Ledger!'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.appState.currentUser;
    final bool hasEnoughBalance = currentUser.walletBalance >= widget.service.price;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pemesanan dengan Escrow Ledger',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          const SizedBox(height: 8),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(fontSize: 11, color: Colors.red.shade800),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Service summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.title,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Penyedia: ${widget.provider.name} (${widget.provider.major})',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  FormatterUtils.formatIDR(widget.service.price),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Escrow protection notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dana ${FormatterUtils.formatIDR(widget.service.price)} dikunci aman di dompet Escrow sistem. Penyedia TIDAK menerima uang sebelum Anda memverifikasi hasil pengerjaan.',
                    style: const TextStyle(fontSize: 11, color: AppTheme.primary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Wallet balance check
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saldo Dompet Demo Anda', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  Text(
                    FormatterUtils.formatIDR(currentUser.walletBalance),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasEnoughBalance ? AppTheme.textPrimary : Colors.red,
                    ),
                  ),
                ],
              ),
              if (!hasEnoughBalance)
                TextButton(
                  onPressed: () {
                    widget.appState.topUpBalance(100000);
                  },
                  child: const Text('+ Top Up Demo (+100k)'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Brief / notes
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Catatan Kebutuhan / Brief Pekerjaan',
              hintText: 'Contoh: Laptop Asus nugas besok jam 2 di Gazebo Saintek...',
            ),
          ),
          const SizedBox(height: 16),

          // Submit CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isLoading || !hasEnoughBalance) ? null : _handleOrder,
              child: _isLoading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Kunci Dana (${FormatterUtils.formatIDR(widget.service.price)}) & Buat Pesanan'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
    );
  }
}
