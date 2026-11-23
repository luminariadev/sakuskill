import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../data/auth_session.dart';

/// Figma "3 · Registrasi akun" (FE-01: FR-01, FR-02).
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _domicile = TextEditingController();

  bool _agree = true;
  bool _submitted = false;
  bool _loading = false;
  String? _authError;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm, _domicile]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _openServerSettings() async {
    final controller = TextEditingController(text: AppConfig.apiBaseUrl);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pengaturan Server API'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sesuaikan URL server backend Cloud (Render/Production) atau gunakan Mode Demo:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'API Base URL',
                  hintText: 'https://sakuskill-backend.onrender.com/api/v1',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Render Cloud (Default)'),
                    onPressed: () => controller.text = 'https://sakuskill-backend.onrender.com/api/v1',
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppConfig.customUseMockData = true;
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Beralih ke Mode Offline Demo')),
              );
              setState(() {});
            },
            child: const Text('Mode Demo'),
          ),
          ElevatedButton(
            onPressed: () {
              AppConfig.customServerUrl = controller.text.trim();
              AppConfig.customUseMockData = false;
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Server API diubah: ${AppConfig.apiBaseUrl}')),
              );
              setState(() {});
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _authError = null;
    });

    final fieldsValid = _formKey.currentState!.validate();
    if (!fieldsValid || !_agree) return;

    if (AppConfig.useMockData) {
      SakuMotion.tick();
      Navigator.of(context).pushReplacementNamed(AppRoutes.profileSetup);
      return;
    }

    setState(() => _loading = true);

    try {
      final phone = _phone.text.trim();
      final domicile = _domicile.text.trim();
      final profileNotes = [
        if (phone.isNotEmpty) 'WA: $phone',
        if (domicile.isNotEmpty) 'Domisili: $domicile',
      ].join(' · ');

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/register');
      final response = await http.post(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nama': _name.text.trim(),
          'email': _email.text.trim(),
          'kata_sandi': _password.text,
          'peran': 'Penyedia Jasa',
          if (profileNotes.isNotEmpty) 'deskripsi_profil': profileNotes,
        }),
      );

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded;
        final token = (data['token'] ??
                data['accessToken'] ??
                data['access_token'] ??
                '')
            .toString();

        if (token.isEmpty) {
          throw Exception('Token autentikasi tidak ditemukan pada respons.');
        }

        final user = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : const <String, dynamic>{};

        AuthSession.instance.save(
          token: token,
          id: user['id']?.toString(),
          name: (user['nama'] ?? _name.text.trim()).toString(),
          userEmail: (user['email'] ?? _email.text.trim()).toString(),
          userRole: (user['peran'] ?? 'Mahasiswa').toString(),
        );

        SakuMotion.tick();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.profileSetup);
      } else {
        final errorObj = decoded['error'];
        final message = errorObj is Map<String, dynamic>
            ? (errorObj['message'] ?? 'Registrasi gagal.').toString()
            : (decoded['message'] ?? 'Registrasi gagal.').toString();

        setState(() => _authError = message);
      }
    } catch (e) {
      setState(() {
        _authError = 'Gagal terhubung ke server (${AppConfig.apiBaseUrl}). Periksa koneksi Wi-Fi atau ganti alamat server.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: SakuScreen(
        showBack: true,
        gap: 12,
        children: [
          const Text(
            'Buat Akun\nSakuSkill Baru',
            style: AppTypography.pageTitle,
          ),
          const Text(
            'Satu akun fleksibel untuk mencari jasa maupun menawarkan keahlian',
            style: AppTypography.body,
          ),
          SakuTextField(
            fieldKey: const Key('register-name'),
            controller: _name,
            label: 'Nama Lengkap',
            hint: 'Salma Nur Oktavia',
            textInputAction: TextInputAction.next,
            validator: SakuValidators.compose([
              SakuValidators.required('Nama lengkap'),
              SakuValidators.maxLength(100),
            ]),
          ),
          SakuTextField(
            fieldKey: const Key('register-email'),
            controller: _email,
            label: 'Alamat Email',
            hint: 'salma@gmail.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: SakuValidators.compose([
              SakuValidators.required('Email'),
              SakuValidators.email(),
            ]),
          ),
          SakuTextField(
            fieldKey: const Key('register-phone'),
            controller: _phone,
            label: 'Nomor WhatsApp Aktif',
            hint: '081223456789',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: SakuValidators.compose([
              SakuValidators.required('Nomor WhatsApp'),
              SakuValidators.phoneId(),
            ]),
          ),
          SakuTextField(
            fieldKey: const Key('register-password'),
            controller: _password,
            label: 'Kata Sandi',
            hint: 'Minimal ${SakuValidators.passwordMinLength} karakter',
            obscure: true,
            textInputAction: TextInputAction.next,
            validator: SakuValidators.compose([
              SakuValidators.required('Kata sandi'),
              SakuValidators.minLength(),
            ]),
          ),
          SakuTextField(
            fieldKey: const Key('register-confirm'),
            controller: _confirm,
            label: 'Konfirmasi Kata Sandi',
            hint: 'Ulangi kata sandi Anda',
            obscure: true,
            textInputAction: TextInputAction.next,
            validator: SakuValidators.compose([
              SakuValidators.required('Konfirmasi kata sandi'),
              SakuValidators.matches(() => _password.text),
            ]),
          ),
          SakuTextField(
            controller: _domicile,
            label: 'Domisili / Lokasi Sekitar',
            hint: 'Cibiru, Bandung Timur',
            textInputAction: TextInputAction.done,
          ),
          SakuCheckRow(
            value: _agree,
            onChanged: (v) => setState(() => _agree = v),
            label:
                'Saya menyetujui Ketentuan Layanan Rekening Bersama Escrow & '
                'Sistem Transaksi SakuSkill.',
            color: _submitted && !_agree
                ? AppColors.danger
                : AppColors.textSecondary,
          ),
          if (_authError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger),
              ),
              child: Text(
                _authError!,
                style: AppTypography.body.copyWith(color: AppColors.danger),
              ),
            ),
          SakuButton(
            key: const Key('register-submit'),
            label: _loading ? 'Mendaftarkan Akun...' : 'Daftar Akun Baru',
            onPressed: _loading ? null : _submit,
          ),
          SakuTextLink(
            'Sudah memiliki akun? Masuk di sini',
            onTap: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.login),
          ),
        ],
      ),
    );
  }
}