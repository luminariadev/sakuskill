import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/campus_constants.dart';
import '../../../../core/security/rbac_matrix.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../admin/domain/entities/dispute_ticket.dart';
import '../../../admin/presentation/pages/admin_dispute_hearing_page.dart';
import '../../../ai_estimator/presentation/widgets/ai_estimator_sheet.dart';
import '../../../escrow/domain/entities/escrow_order.dart';
import '../../../services/presentation/providers/app_state_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showTopUpSheet(BuildContext context, AppStateProvider appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Isi Saldo Dompet SakuSkill',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Text(
                'Saldo digunakan untuk memesan jasa mahasiswa dengan jaminan Escrow Ledger aman:',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ...[25000, 50000, 100000, 200000].map((nominal) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primary),
                      title: Text(
                        FormatterUtils.formatIDR(nominal),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      subtitle: const Text('Simulasi Top Up Instan Kampus', style: TextStyle(fontSize: 11)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          appState.topUpBalance(nominal);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Top Up ${FormatterUtils.formatIDR(nominal)} berhasil ditambahkan ke saldo!'),
                              backgroundColor: AppTheme.primary,
                            ),
                          );
                        },
                        child: const Text('Pilih'),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGigDialog(BuildContext context, AppStateProvider appState) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController(text: '45000');
    final wishlistController = TextEditingController();
    ServiceCategory category = ServiceCategory.itSupport;
    bool acceptsBarter = true;
    int deliveryHours = 4;
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.90,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.add_business, color: AppTheme.primary, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Publikasikan Jasa Baru (Gig)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (errorText != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        errorText!,
                        style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  const Text('Judul Jasa (Gig Title)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(hintText: 'Contoh: Pembersihan Kipas & Repasta Laptop'),
                  ),
                  const SizedBox(height: 12),

                  const Text('Kategori', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<ServiceCategory>(
                    initialValue: category,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: ServiceCategory.values
                        .map((c) => DropdownMenuItem(value: c, child: Text(CategoryMeta.info[c]!.label)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tarif Mulai Dari (IDR)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '45000'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                              builder: (_) => AIEstimatorSheet(
                                initialTitle: titleController.text,
                                initialCategory: category,
                                onApplyPrice: (recPrice) {
                                  setSheetState(() => priceController.text = recPrice.toString());
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.auto_awesome, size: 14, color: AppTheme.primary),
                          label: const Text('Cek AI', style: TextStyle(fontSize: 11, color: AppTheme.primary)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const Text('Deskripsi Layanan & Garansi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Jelaskan pengerjaan transparan Anda di kampus...'),
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    value: acceptsBarter,
                    onChanged: (val) => setSheetState(() => acceptsBarter = val),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Menerima Smart Barter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Bisa bertukar keahlian tanpa uang tunai', style: TextStyle(fontSize: 11)),
                    activeThumbColor: AppTheme.accentPurple,
                  ),

                  if (acceptsBarter) ...[
                    const SizedBox(height: 4),
                    TextField(
                      controller: wishlistController,
                      decoration: const InputDecoration(
                        hintText: 'Keahlian yang Anda butuhkan (contoh: bantuan desain banner)',
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final parsedPrice = int.tryParse(priceController.text) ?? 35000;
                        final err = appState.createService(
                          title: titleController.text,
                          description: descController.text,
                          category: category,
                          price: parsedPrice,
                          acceptsBarter: acceptsBarter,
                          barterWishlist: wishlistController.text,
                          locationName: appState.currentUser.locationName,
                          coordinates: appState.currentUser.coordinates,
                          estimatedDeliveryHours: deliveryHours,
                          imageUrl: 'https://images.unsplash.com/photo-1588508065123-287b28e013da?auto=format&fit=crop&w=800&q=80',
                        );

                        if (err != null) {
                          setSheetState(() => errorText = err);
                        } else {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Jasa baru berhasil dipublikasikan ke Discovery Feed!'),
                              backgroundColor: AppTheme.primary,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Publikasikan Sekarang'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showHonorCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: AppTheme.primary, size: 22),
            SizedBox(width: 8),
            Text('Pakta Integritas Kampus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Prinsip Bebas Joki & Etika Akademik UIN Sunan Gunung Djati:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
              ),
              SizedBox(height: 10),
              Text(
                '1. Dilarang Keras Perjokian Akademik:\nSeluruh transaksi jasa pembuatan skripsi, tesis, makalah, tugas mata kuliah, atau ujian dilarang mutlak dan akan disanksi komite etik kemahasiswaan.\n\n'
                '2. Jasa Sah Yang Didukung:\nLayanan teknikal (servis laptop, instalasi Linux/Windows), jasa kreatif (desain poster kegiatan himpunan, foto wisuda, editing video UKM), dan bimbingan logika belajar.\n\n'
                '3. Perlindungan Escrow Ledger:\nDana pesanan disimpan aman di sistem kampus dan hanya dicairkan setelah kedua belah pihak menyetujui hasil deliverable.',
                style: TextStyle(fontSize: 11.5, height: 1.4, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Saya Mengerti & Patuh'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final user = appState.currentUser;
    final isProvider = user.role == UserRole.provider;
    final isAdmin = user.role == UserRole.campusAdmin;
    final isClient = user.role == UserRole.client;

    final myGigs = appState.currentUserServices;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_calls_outlined),
            tooltip: 'Ganti Akun Demo (Uji RBAC)',
            onPressed: () {
              // Trigger switcher from profile
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (ctx) => ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ganti Akun Demo (Uji RBAC)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...appState.users.map((u) {
                          final isCur = u.id == user.id;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isCur ? AppTheme.primarySurface : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isCur ? AppTheme.primary : AppTheme.border),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(backgroundImage: NetworkImage(u.avatar)),
                              title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              subtitle: Text('${u.major} • ${u.role.name.toUpperCase()}', style: const TextStyle(fontSize: 11)),
                              trailing: isCur ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
                              onTap: () {
                                appState.switchUser(u.id);
                                Navigator.pop(ctx);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Keluar',
            onPressed: () => appState.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: NetworkImage(user.avatar),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.major,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user.faculty,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: AppTheme.starGold),
                                const SizedBox(width: 3),
                                Text(
                                  user.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${user.reviewCount} ulasan)',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isAdmin
                                        ? Colors.red.shade50
                                        : isProvider
                                            ? AppTheme.primarySurface
                                            : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isAdmin
                                          ? Colors.red.shade200
                                          : isProvider
                                              ? AppTheme.primary.withValues(alpha: 0.3)
                                              : Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    isAdmin
                                        ? 'ADMIN KAMPUS'
                                        : isProvider
                                            ? 'FREELANCER'
                                            : 'KLIEN',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: isAdmin
                                          ? Colors.red.shade800
                                          : isProvider
                                              ? AppTheme.primary
                                              : Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.border, height: 1),
                  const SizedBox(height: 10),

                  // Verification footer
                  Row(
                    children: [
                      const Icon(Icons.verified, size: 15, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          user.role == UserRole.campusAdmin
                              ? 'Pejabat Kemahasiswaan & Komite Integritas UIN SGD'
                              : 'Mahasiswa Aktif Terverifikasi (${user.nim})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // SakuSkill Wallet Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F5132), Color(0xFF1DBF73)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SALDO DOMPET ESCROW SAKUSKILL',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FormatterUtils.formatIDR(user.walletBalance),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Aman terkunci per transaksi pengerjaan',
                        style: TextStyle(fontSize: 10.5, color: Colors.white70),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showTopUpSheet(context, appState),
                    icon: const Icon(Icons.add, size: 16, color: AppTheme.primary),
                    label: const Text('Top Up', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- ROLE SPECIFIC DASHBOARD ---

            // 1. CAMPUS ADMIN VIEW (Dr. Mulyana)
            if (isAdmin) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel, color: Colors.red.shade800, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Panel Pengawasan Komite Etik Kampus',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.red.shade900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sebagai pejabat Komite Etik Kemahasiswaan UIN SGD, Anda memiliki hak istimewa (RBAC) untuk menyelesaikan sengketa deliverable dan mengeksekusi pencairan escrow.',
                      style: TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatBox('Sengketa Terbuka', '${appState.disputes.where((d) => d.status == DisputeStatus.open).length}', Colors.red.shade800),
                        const SizedBox(width: 10),
                        _buildStatBox('Selesai Mediasi', '${appState.disputes.where((d) => d.status == DisputeStatus.resolved).length}', Colors.green.shade800),
                        const SizedBox(width: 10),
                        _buildStatBox('Kasus Joki', '0 (Bebas)', Colors.blue.shade800),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminDisputeHearingPage()),
                          );
                        },
                        icon: const Icon(Icons.meeting_room, size: 16),
                        label: const Text('Buka Ruang Sidang Mediasi'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 2. PROVIDER VIEW (Ahmad / Siti / Rizky)
            if (isProvider) ...[
              // Freelancer Metrics (Fiverr Seller Dashboard)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PERFORMA FREELANCER KAMPUS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatBox('Tingkat Respons', '100%', AppTheme.primary),
                        const SizedBox(width: 8),
                        _buildStatBox('Tepat Waktu', '98%', AppTheme.primary),
                        const SizedBox(width: 8),
                        _buildStatBox('Penyelesaian', '100%', AppTheme.primary),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // My Gigs Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jasa Aktif Saya (${myGigs.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddGigDialog(context, appState),
                    icon: const Icon(Icons.add, size: 16, color: AppTheme.primary),
                    label: const Text('+ Tambah Gig', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (myGigs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 36, color: AppTheme.textMuted),
                        const SizedBox(height: 8),
                        const Text('Belum ada gig yang dipublikasikan.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _showAddGigDialog(context, appState),
                          child: const Text('Buat Gig Pertama Anda'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...myGigs.map((g) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              g.imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: AppTheme.border),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.title,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      FormatterUtils.formatIDR(g.price),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary),
                                    ),
                                    if (g.acceptsBarter) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFAF5FF),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Barter Aktif', style: TextStyle(fontSize: 9, color: AppTheme.accentPurple, fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 20),
            ],

            // 3. CLIENT VIEW (Farhan Pratama)
            if (isClient) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AKTIVITAS PESANAN KLIEN',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatBox('Pesanan Aktif', '${appState.activeOrdersCount}', AppTheme.primary),
                        const SizedBox(width: 8),
                        _buildStatBox('Smart Barter', '${appState.barterContracts.length}', AppTheme.accentPurple),
                        const SizedBox(width: 8),
                        _buildStatBox('Selesai', '${appState.orders.where((o) => o.status == EscrowStatus.completed).length}', Colors.blue.shade800),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Verified Skills Tags
            const Text(
              'Keahlian Terverifikasi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: user.skills.map((s) => Chip(
                    backgroundColor: AppTheme.primarySurface,
                    label: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                    avatar: const Icon(Icons.check, size: 14, color: AppTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  )).toList(),
            ),
            const SizedBox(height: 20),

            // Account & Ethics Menu
            const Text(
              'Pengaturan & Integritas Kampus',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: AppTheme.primary),
                    title: const Text('Pakta Integritas Mahasiswa (Anti-Joki)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Prinsip kepatuhan etika akademik UIN SGD', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => _showHonorCodeDialog(context),
                  ),
                  const Divider(color: AppTheme.border, height: 1),
                  ListTile(
                    leading: const Icon(Icons.pin_drop_outlined, color: AppTheme.primary),
                    title: const Text('Lokasi Kampus Utama', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    subtitle: Text(user.locationName, style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                  ),
                  const Divider(color: AppTheme.border, height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('Keluar dari Akun (Logout)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.redAccent)),
                    onTap: () => appState.logout(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
