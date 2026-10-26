import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/service_item.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/app_state_provider.dart';

class BarterProposalDialog extends StatefulWidget {
  final ServiceItem service;
  final UserEntity partner;
  final AppStateProvider appState;

  const BarterProposalDialog({
    super.key,
    required this.service,
    required this.partner,
    required this.appState,
  });

  @override
  State<BarterProposalDialog> createState() => _BarterProposalDialogState();
}

class _BarterProposalDialogState extends State<BarterProposalDialog> {
  final _offeredServiceController = TextEditingController();
  final _termsController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _offeredServiceController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_offeredServiceController.text.trim().isEmpty || _termsController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Mohon lengkapi jasa yang ditawarkan dan ketentuan pengerjaan.');
      return;
    }

    final error = widget.appState.createBarterProposal(
      partnerId: widget.service.providerId,
      initiatorServiceTitle: _offeredServiceController.text.trim(),
      partnerServiceTitle: widget.service.title,
      terms: _termsController.text.trim(),
    );

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proposal Smart Barter berhasil diajukan!'),
          backgroundColor: AppTheme.accentPurple,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.swap_horiz, color: AppTheme.accentPurple, size: 20),
          SizedBox(width: 8),
          Text('Ajukan Smart Barter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
              const SizedBox(height: 8),
            ],
            // Partner wishlist info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jasa Mitra: ${widget.service.title}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  if (widget.service.barterWishlist != null)
                    Text(
                      'Keinginan Mitra: "${widget.service.barterWishlist}"',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _offeredServiceController,
              decoration: const InputDecoration(
                labelText: 'Keahlian yang Anda Tawarkan',
                hintText: 'Contoh: Instalasi Linux Dual-Boot, Desain Banner...',
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _termsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ketentuan & Batas Waktu',
                hintText: 'Contoh: Selesai dalam 2 hari via Google Drive...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
          child: const Text('Kirim Proposal'),
        ),
      ],
    );
  }
}
