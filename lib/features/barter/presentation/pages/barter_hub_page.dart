import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakuskill_mobile/core/theme/app_theme.dart';
import 'package:sakuskill_mobile/features/barter/domain/entities/barter_contract.dart';
import 'package:sakuskill_mobile/features/services/presentation/providers/app_state_provider.dart';

class BarterHubPage extends StatelessWidget {
  const BarterHubPage({super.key});

  void _showUploadProofDialog(BuildContext context, BarterContract contract, bool isInitiator, AppStateProvider appState) {
    final proofCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unggah Bukti Deliverable Barter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: TextField(
            controller: proofCtrl,
            decoration: const InputDecoration(
              labelText: 'Tautan Deliverable (HTTPS)',
              hintText: 'https://drive.google.com/...',
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final err = appState.submitBarterDeliverable(
                contractId: contract.id,
                isInitiator: isInitiator,
                proofUrl: proofCtrl.text,
              );
              Navigator.pop(ctx);
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deliverable barter berhasil diunggah!'), backgroundColor: AppTheme.accentPurple));
              }
            },
            child: const Text('Kirim Bukti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final currentUser = appState.currentUser;
    final contracts = appState.barterContracts.where((c) => c.initiatorId == currentUser.id || c.partnerId == currentUser.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Barter Hub'),
      ),
      body: contracts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.swap_horiz, size: 48, color: AppTheme.textMuted),
                  SizedBox(height: 8),
                  Text('Belum ada kontrak barter aktif', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contracts.length,
              itemBuilder: (context, index) {
                final contract = contracts[index];
                final isInitiator = contract.initiatorId == currentUser.id;
                final partnerUser = appState.users.firstWhere((u) => u.id == (isInitiator ? contract.partnerId : contract.initiatorId));

                final myDeliverable = isInitiator ? contract.initiatorDeliverableProof : contract.partnerDeliverableProof;
                final partnerDeliverable = isInitiator ? contract.partnerDeliverableProof : contract.initiatorDeliverableProof;
                final myApproved = isInitiator ? contract.initiatorApproved : contract.partnerApproved;

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
                            Text('#${contract.id}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.textMuted)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: contract.status == BarterStatus.completed ? const Color(0xFFECFDF5) : Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                contract.status == BarterStatus.completed ? 'Selesai Penuh' : 'Tahap Verifikasi',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: contract.status == BarterStatus.completed ? const Color(0xFF065F46) : Colors.purple.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Kesepakatan Barter:', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                        Text('"${contract.termsAndAgreement}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 10),

                        // Bilateral columns
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Anda: ${isInitiator ? contract.initiatorServiceTitle : contract.partnerServiceTitle}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              Text(myDeliverable != null ? 'Bukti: $myDeliverable' : 'Bukti: Belum diunggah', style: TextStyle(fontSize: 11, color: myDeliverable != null ? Colors.blue : Colors.amber.shade900)),
                              const SizedBox(height: 6),
                              Text('Mitra (${partnerUser.name}): ${isInitiator ? contract.partnerServiceTitle : contract.initiatorServiceTitle}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              Text(partnerDeliverable != null ? 'Bukti: $partnerDeliverable' : 'Bukti: Belum diunggah', style: TextStyle(fontSize: 11, color: partnerDeliverable != null ? Colors.blue : Colors.amber.shade900)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (myDeliverable == null)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
                                onPressed: () => _showUploadProofDialog(context, contract, isInitiator, appState),
                                child: const Text('Unggah Deliverable Saya', style: TextStyle(fontSize: 11)),
                              ),
                            if (partnerDeliverable != null && !myApproved) ...[
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  appState.approveBarterContract(contractId: contract.id, isInitiator: isInitiator);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Persetujuan barter berhasil dicatat!'), backgroundColor: AppTheme.primary));
                                },
                                child: const Text('Konfirmasi Hasil Mitra Sesuai', style: TextStyle(fontSize: 11)),
                              ),
                            ],
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
