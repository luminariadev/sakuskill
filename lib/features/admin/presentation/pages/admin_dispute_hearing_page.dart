import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakuskill_mobile/core/security/rbac_matrix.dart';
import 'package:sakuskill_mobile/core/theme/app_theme.dart';
import 'package:sakuskill_mobile/features/services/presentation/providers/app_state_provider.dart';
import 'package:sakuskill_mobile/features/admin/domain/entities/dispute_ticket.dart';

class AdminDisputeHearingPage extends StatelessWidget {
  const AdminDisputeHearingPage({super.key});

  void _showResolveDialog(BuildContext context, DisputeTicket ticket, AppStateProvider appState) {
    ResolutionAction action = ResolutionAction.refundToBuyer;
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sidang Mediasi Komite Etik', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alasan Sengketa: ${ticket.reason}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const Text('Pilih Amar Putusan Mediasi:', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                DropdownButton<ResolutionAction>(
                  value: action,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: ResolutionAction.refundToBuyer, child: Text('Refund 100% ke Klien', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: ResolutionAction.releaseToSeller, child: Text('Cairkan 100% ke Penyedia', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: ResolutionAction.split5050, child: Text('Split 50:50 Mediasi Damai', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => action = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Dasar Pertimbangan Mediasi',
                    hintText: 'Pertimbangan komite etik kampus...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final err = appState.resolveDispute(
                  disputeId: ticket.id,
                  action: action,
                  notes: notesCtrl.text,
                );
                Navigator.pop(ctx);
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Putusan berhasil disahkan dan dana escrow dieksekusi!'), backgroundColor: AppTheme.primary));
                }
              },
              child: const Text('Eksekusi Putusan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final currentUser = appState.currentUser;

    // STRICT RBAC GATE: 403 Forbidden for non-admins
    if (currentUser.role != UserRole.campusAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Komite Etik')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.lock_outline, size: 40, color: Colors.red.shade700),
                ),
                const SizedBox(height: 16),
                const Text(
                  'HTTP 403: Akses Ditolak',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Halaman mediasi sengketa dan eksekusi dana dilindungi oleh sistem RBAC. Hanya akun Komite Etik Kampus (CAMPUS_ADMIN) yang memiliki hak wewenang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.gavel, size: 16),
                  label: const Text('Beralih ke Akun Komite Etik (user-5)'),
                  onPressed: () {
                    appState.switchUser('user-5'); // Dr. H. Mulyana
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final disputes = appState.disputes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Mediasi Komite Etik UIN SGD'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: disputes.length,
        itemBuilder: (context, index) {
          final ticket = disputes[index];
          final claimant = appState.users.firstWhere((u) => u.id == ticket.raisedById);

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
                      Text('Perkara #${ticket.id}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.textMuted)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ticket.status == DisputeStatus.open ? Colors.amber.shade50 : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          ticket.status == DisputeStatus.open ? 'Perlu Sidang' : 'Selesai Diputus',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ticket.status == DisputeStatus.open ? Colors.amber.shade900 : const Color(0xFF065F46)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Pelapor: ${claimant.name} (${claimant.major})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Alasan Komplain: "${ticket.reason}"', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  Text('Bukti: ${ticket.evidenceNotes}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),

                  if (ticket.status == DisputeStatus.resolved) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                      child: Text('Putusan: ${ticket.resolutionAction?.name} - ${ticket.resolutionNotes}', style: const TextStyle(fontSize: 11, color: Color(0xFF065F46))),
                    ),
                  ],

                  if (ticket.status == DisputeStatus.open) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.gavel, size: 14),
                        label: const Text('Sidangkan Perkara', style: TextStyle(fontSize: 11)),
                        onPressed: () => _showResolveDialog(context, ticket, appState),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
