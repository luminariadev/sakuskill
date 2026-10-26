import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakuskill_mobile/core/theme/app_theme.dart';
import 'package:sakuskill_mobile/core/utils/currency_formatter.dart';
import 'package:sakuskill_mobile/features/escrow/domain/entities/escrow_order.dart';
import 'package:sakuskill_mobile/features/services/presentation/providers/app_state_provider.dart';

class EscrowOrdersPage extends StatefulWidget {
  const EscrowOrdersPage({super.key});

  @override
  State<EscrowOrdersPage> createState() => _EscrowOrdersPageState();
}

class _EscrowOrdersPageState extends State<EscrowOrdersPage> {
  final _proofUrlController = TextEditingController();
  final _proofNotesController = TextEditingController();

  @override
  void dispose() {
    _proofUrlController.dispose();
    _proofNotesController.dispose();
    super.dispose();
  }

  void _showSubmitProofDialog(BuildContext context, EscrowOrder order, AppStateProvider appState) {
    _proofUrlController.clear();
    _proofNotesController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unggah Bukti Deliverable', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _proofUrlController,
                decoration: const InputDecoration(
                  labelText: 'Tautan Hasil Kerja (HTTPS URL)',
                  hintText: 'https://drive.google.com/...',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _proofNotesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan untuk Klien',
                  hintText: 'Hasil perbaikan laptop / banner sudah selesai...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final err = appState.submitDeliverable(
                orderId: order.id,
                proofUrl: _proofUrlController.text,
                notes: _proofNotesController.text,
              );
              Navigator.pop(ctx);
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deliverable berhasil dikirim ke klien!'), backgroundColor: AppTheme.primary));
              }
            },
            child: const Text('Kirim ke Klien'),
          ),
        ],
      ),
    );
  }

  void _showDisputeDialog(BuildContext context, EscrowOrder order, AppStateProvider appState) {
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buka Tiket Mediasi Komite Etik', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alasan Sengketa',
                  hintText: 'Pekerjaan tidak sesuai brief...',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Kronologi / Bukti',
                  hintText: 'Penyedia tidak merespons chat revisi...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              final err = appState.openDispute(
                transactionId: order.id,
                orderType: 'ESCROW',
                reason: reasonCtrl.text,
                evidenceNotes: notesCtrl.text,
              );
              Navigator.pop(ctx);
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiket sengketa berhasil didaftarkan ke Komite Etik!'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Kirim Tiket Sengketa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final currentUser = appState.currentUser;
    final orders = appState.orders.where((o) => o.buyerId == currentUser.id || o.sellerId == currentUser.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan & Escrow Ledger'),
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textMuted),
                  SizedBox(height: 8),
                  Text('Belum ada pesanan aktif', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final isBuyer = order.buyerId == currentUser.id;
                final counterparty = appState.users.firstWhere((u) => u.id == (isBuyer ? order.sellerId : order.buyerId));

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('#${order.id}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.textMuted)),
                            _StatusBadge(status: order.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order.serviceTitle,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBuyer ? 'Penyedia: ${counterparty.name}' : 'Klien: ${counterparty.name}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Nilai Escrow Tertahan', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                            Text(
                              FormatterUtils.formatIDR(order.amount),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary),
                            ),
                          ],
                        ),

                        // Deliverable info if submitted
                        if (order.deliverableProofUrl != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link, size: 14, color: Colors.blue),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    order.deliverableProofUrl!,
                                    style: const TextStyle(fontSize: 11, color: Colors.blue, decoration: TextDecoration.underline),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: 8),

                        // Action buttons based on Role & State
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (order.status != EscrowStatus.completed && order.status != EscrowStatus.refunded && order.status != EscrowStatus.dispute)
                              TextButton(
                                onPressed: () => _showDisputeDialog(context, order, appState),
                                child: const Text('Komplain / Sengketa', style: TextStyle(fontSize: 11, color: Colors.red)),
                              ),
                            const SizedBox(width: 8),

                            // Seller submit work
                            if (!isBuyer && order.status == EscrowStatus.escrowLocked)
                              ElevatedButton(
                                onPressed: () => _showSubmitProofDialog(context, order, appState),
                                child: const Text('Unggah Bukti Deliverable', style: TextStyle(fontSize: 11)),
                              ),

                            // Buyer release funds
                            if (isBuyer && order.status == EscrowStatus.workSubmitted)
                              ElevatedButton(
                                onPressed: () {
                                  final err = appState.completeEscrowOrder(order.id);
                                  if (err != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pekerjaan selesai! Dana escrow telah dicairkan ke penyedia.'), backgroundColor: AppTheme.primary));
                                  }
                                },
                                child: const Text('Konfirmasi & Cairkan Dana', style: TextStyle(fontSize: 11)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final EscrowStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case EscrowStatus.escrowLocked:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'Escrow Terkunci';
        break;
      case EscrowStatus.workSubmitted:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade900;
        label = 'Bukti Diserahkan';
        break;
      case EscrowStatus.completed:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF065F46);
        label = 'Selesai & Cair';
        break;
      case EscrowStatus.dispute:
        bg = Colors.red.shade50;
        fg = Colors.red.shade900;
        label = 'Mediasi Komite';
        break;
      case EscrowStatus.refunded:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        label = 'Refunded';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        label = status.name;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
