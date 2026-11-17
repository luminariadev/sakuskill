import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../../data/auth_session.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';

/// Figma "2 · Login pengguna".
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _failed = false;
  bool _loading = false;
  String _errorMessage =
      'Email atau kata sandi tidak sesuai. Silakan coba lagi.';

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _failed = false);
    if (!_formKey.currentState!.validate()) return;

    if (AppConfig.useMockData) {
      final credentialsOk =
          _password.text.length >= SakuValidators.passwordMinLength;
      if (!credentialsOk) {
        setState(() => _failed = true);
        return;
      }
      SakuMotion.tick();
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
      return;
    }

    setState(() => _loading = true);

    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/auth/login');
      final response = await http.post(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _id.text.trim(),
          'kata_sandi': _password.text,
        }),
      );

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded;
        final tokens = data['tokens'] is Map<String, dynamic>
            ? data['tokens'] as Map<String, dynamic>
            : data;
        final user = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : const <String, dynamic>{};

        final token = (tokens['access_token'] ??
                tokens['accessToken'] ??
                tokens['token'] ??
                '')
            .toString();

        if (token.isEmpty) {
          throw Exception('Token autentikasi tidak ditemukan pada respons.');
        }

        AuthSession.instance.save(
          token: token,
          id: user['id']?.toString(),
          name: (user['nama'] ?? user['nama_lengkap'] ?? user['name'])?.toString(),
          userEmail: user['email']?.toString(),
          userRole: user['peran']?.toString(),
        );

        if (!mounted) return;
        SakuMotion.tick();
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
      } else {
        final errorObj = decoded['error'] is Map<String, dynamic>
            ? decoded['error'] as Map<String, dynamic>
            : const <String, dynamic>{};
        setState(() {
          _errorMessage = (errorObj['message'] ??
                  decoded['message'] ??
                  'Email atau kata sandi tidak sesuai. Silakan coba lagi.')
              .toString();
          _failed = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal terhubung ke server: $e';
        _failed = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                'Sesuaikan alamat backend untuk pengujian di HP fisik / Wi-Fi:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'API Base URL',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Wi-Fi Laptop (192.168.101.9)'),
                    onPressed: () => controller.text = 'http://192.168.101.9:3000/api/v1',
                  ),
                  ActionChip(
                    label: const Text('Emulator (10.0.2.2)'),
                    onPressed: () => controller.text = 'http://10.0.2.2:3000/api/v1',
                  ),
                  ActionChip(
                    label: const Text('USB Reverse (127.0.0.1)'),
                    onPressed: () => controller.text = 'http://127.0.0.1:3000/api/v1',
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SakuScreen(
        showBack: true,
        children: [
          const Text(
            'Selamat Datang\nKembali',
            style: TextStyle(
              fontSize: 28,
              height: 39 / 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'Masuk untuk mencari jasa atau mengelola penawaran Anda',
            style: AppTypography.body,
          ),
          SakuTextField(
            fieldKey: const Key('login-id'),
            controller: _id,
            label: 'Email / No. WhatsApp',
            hint: 'salma@gmail.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            errorText: _failed ? '' : null,
            validator: SakuValidators.required('Email / No. WhatsApp'),
            onChanged: (_) {
              if (_failed) setState(() => _failed = false);
            },
          ),
          SakuTextField(
            fieldKey: const Key('login-password'),
            controller: _password,
            label: 'Kata Sandi',
            hint: '••••••••',
            obscure: true,
            textInputAction: TextInputAction.done,
            errorText: _failed ? '' : null,
            validator: SakuValidators.required('Kata sandi'),
            onChanged: (_) {
              if (_failed) setState(() => _failed = false);
            },
          ),
          Row(
            children: [
              Expanded(
                child: SakuCheckRow(
                  value: _remember,
                  onChanged: (v) => setState(() => _remember = v),
                  label: 'Ingat Saya',
                  color: AppColors.primary,
                  fontSize: 12,
                  bold: true,
                ),
              ),
              SakuTextLink(
                'Lupa Kata Sandi?',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tautan reset dikirim ke email / WhatsApp Anda.',
                    ),
                  ),
                ),
              ),
            ],
          ),
          SakuButton(
            key: const Key('login-submit'),
            label: _loading ? 'Memproses Masuk...' : 'Masuk Sekarang',
            onPressed: _loading ? null : _submit,
          ),
          AnimatedSwitcher(
            duration: SakuMotion.base,
            transitionBuilder: (child, a) => SizeTransition(
              sizeFactor: a,
              child: FadeTransition(opacity: a, child: child),
            ),
            child: _failed
                ? InfoBox(
                    key: const ValueKey('login-error'),
                    text: _errorMessage,
                    tone: SakuTone.danger,
                  )
                : const SizedBox(key: ValueKey('ok'), width: double.infinity),
          ),
          const Center(
            child: Text(
              'atau masuk lebih cepat dengan',
              style: TextStyle(
                fontSize: 12,
                height: 17 / 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SakuButton(
            label: 'G   Lanjutkan dengan Akun Google',
            variant: SakuButtonVariant.outline,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Masuk dengan Google segera hadir.'),
              ),
            ),
          ),
          SakuTextLink(
            'Belum memiliki akun? Daftar Akun Baru di sini',
            onTap: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.register),
          ),
        ],
      ),
    );
  }
}