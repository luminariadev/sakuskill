import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/security/rbac_matrix.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../services/presentation/providers/app_state_provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login controllers
  final _loginIdController = TextEditingController(text: '1238010045'); // Farhan default
  final _loginPasswordController = TextEditingController(text: 'password123');

  // Register controllers
  final _regNameController = TextEditingController();
  final _regNimController = TextEditingController();
  final _regFacultyController = TextEditingController(text: 'Sains dan Teknologi');
  final _regMajorController = TextEditingController(text: 'Teknik Informatika');
  final _regPhoneController = TextEditingController();
  UserRole _selectedRole = UserRole.client;
  bool _agreedToHonorCode = true;

  final List<String> _selectedSkills = [];
  final List<String> _availableSkillTags = [
    'Reparasi Laptop',
    'Install Linux',
    'Desain Banner',
    'Logo Ormawa',
    'Foto Wisuda',
    'Video Reels UKM',
    'Format Excel / RAB',
    'Bahasa Inggris / Arab',
  ];

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginIdController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regNimController.dispose();
    _regFacultyController.dispose();
    _regMajorController.dispose();
    _regPhoneController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final input = _loginIdController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = 'Masukkan NIM atau Email SSO Kampus.');
      return;
    }

    final appState = context.read<AppStateProvider>();
    final user = appState.users.cast<dynamic>().firstWhere(
      (u) => u.nim.toLowerCase().contains(input.toLowerCase()) || u.id.toLowerCase() == input.toLowerCase() || u.name.toLowerCase().contains(input.toLowerCase()),
      orElse: () => null,
    );

    if (user != null) {
      appState.login(user.id);
    } else {
      // Default to Farhan if not matching exact demo ID
      appState.login('user-4');
    }
  }

  void _handleRegister() {
    if (_regNameController.text.trim().isEmpty || _regNimController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Mohon isi nama lengkap dan NIM mahasiswa.');
      return;
    }

    if (!_agreedToHonorCode) {
      setState(() => _errorMessage = 'Anda wajib menyetujui Pakta Integritas Kampus (Bebas Joki).');
      return;
    }

    final appState = context.read<AppStateProvider>();
    appState.registerUser(
      name: _regNameController.text.trim(),
      nim: _regNimController.text.trim(),
      major: _regMajorController.text.trim(),
      faculty: _regFacultyController.text.trim(),
      role: _selectedRole,
      skills: _selectedSkills.isEmpty ? ['Keahlian Praktis Mahasiswa'] : _selectedSkills,
      phone: _regPhoneController.text.trim().isNotEmpty ? _regPhoneController.text.trim() : '081234567890',
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SakuSkill Wordmark & Campus Tagline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'sakuskill',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                letterSpacing: -1.2,
                              ),
                            ),
                            TextSpan(
                              text: '.',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySurface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'UIN SGD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Icon(Icons.school, size: 20, color: AppTheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Marketplace Keahlian & Smart Barter Mahasiswa UIN Sunan Gunung Djati Cibiru Bandung',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 24),

              // Quick 1-Click Demo Login Banner (Highlight for testing RBAC)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.touch_app, size: 16, color: AppTheme.primary),
                        SizedBox(width: 6),
                        Text(
                          'Masuk Cepat 1-Klik Akun Demo (Uji Role)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: appState.users.map((u) {
                          final roleLabel = u.role == UserRole.campusAdmin
                              ? 'Admin Kampus'
                              : u.role == UserRole.provider
                                  ? 'Penyedia Jasa'
                                  : 'Klien';
                          final roleColor = u.role == UserRole.campusAdmin
                              ? Colors.red.shade700
                              : u.role == UserRole.provider
                                  ? AppTheme.primary
                                  : Colors.blue.shade700;

                          return InkWell(
                            onTap: () => appState.login(u.id),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundImage: NetworkImage(u.avatar),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.name.split(' ').first,
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                                      ),
                                      Text(
                                        roleLabel,
                                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: roleColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Segmented Tab Bar (Login vs Register)
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  labelColor: AppTheme.textPrimary,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Masuk'),
                    Tab(text: 'Daftar Baru'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(fontSize: 11, color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tab Views
              SizedBox(
                height: 480,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // --- TAB 1: LOGIN ---
                    _buildLoginForm(),

                    // --- TAB 2: REGISTER ---
                    _buildRegisterForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selamat Datang Kembali',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Masuk menggunakan akun mahasiswa / SSO UIN SGD Bandung',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),

        const Text('NIM / ID Mahasiswa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _loginIdController,
          decoration: const InputDecoration(
            hintText: 'Contoh: 1238010045 (Farhan)',
            prefixIcon: Icon(Icons.badge_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 14),

        const Text('Kata Sandi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _loginPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: '••••••••',
            prefixIcon: Icon(Icons.lock_outline, size: 20),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleLogin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Masuk ke SakuSkill'),
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.verified_user, size: 14, color: AppTheme.primary),
              SizedBox(width: 6),
              Text(
                'Terlindungi Single Sign-On Kampus UIN SGD',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buat Akun Mahasiswa Baru',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bergabung dengan jaringan talenta kampus UIN Sunan Gunung Djati',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          const Text('Nama Lengkap Sesuai KTM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: _regNameController,
            decoration: const InputDecoration(
              hintText: 'Nama lengkap Anda',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NIM Mahasiswa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _regNimController,
                      decoration: const InputDecoration(
                        hintText: '12270500...',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _regPhoneController,
                      decoration: const InputDecoration(
                        hintText: '0812...',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text('Program Studi & Fakultas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: _regMajorController,
            decoration: const InputDecoration(
              hintText: 'Jurusan / Prodi Anda',
              prefixIcon: Icon(Icons.account_balance, size: 20),
            ),
          ),
          const SizedBox(height: 14),

          // Role selection
          const Text('Pilih Peran Utama di Kampus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Pencari Jasa (Klien)')),
                  selected: _selectedRole == UserRole.client,
                  selectedColor: AppTheme.primary,
                  onSelected: (val) {
                    if (val) setState(() => _selectedRole = UserRole.client);
                  },
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _selectedRole == UserRole.client ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Penyedia (Freelancer)')),
                  selected: _selectedRole == UserRole.provider,
                  selectedColor: AppTheme.primary,
                  onSelected: (val) {
                    if (val) setState(() => _selectedRole = UserRole.provider);
                  },
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _selectedRole == UserRole.provider ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Skills Chips
          const Text('Keahlian / Minat Praktis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _availableSkillTags.map((tag) {
              final isSel = _selectedSkills.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSel,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSkills.add(tag);
                    } else {
                      _selectedSkills.remove(tag);
                    }
                  });
                },
                selectedColor: AppTheme.primarySurface,
                checkmarkColor: AppTheme.primary,
                labelStyle: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? AppTheme.primary : AppTheme.textPrimary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Honor code checkbox
          CheckboxListTile(
            value: _agreedToHonorCode,
            onChanged: (val) => setState(() => _agreedToHonorCode = val ?? false),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              'Saya menyetujui Pakta Integritas Mahasiswa UIN SGD: Bebas perjokian tugas akademik/skripsi & menjunjung kejujuran.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppTheme.primary,
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleRegister,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Daftarkan Akun & Dapatkan Bonus Saldo'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
