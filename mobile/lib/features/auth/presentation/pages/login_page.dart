import 'package:flutter/material.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/network/api_exception.dart';
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

    final auth = AppScope.of(context).authRepository;
    final navigator = Navigator.of(context);
    setState(() => _loading = true);

    try {
      await auth.login(email: _id.text.trim(), password: _password.text);
      if (!mounted) return;
      SakuMotion.tick();
      navigator.pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.isConnectivity || e.code == ApiException.invalidResponseError) {
          _errorMessage = e.message;
        } else {
          _errorMessage =
              'Email atau kata sandi tidak sesuai. Silakan coba lagi.';
        }
        _failed = true;
      });
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

  void _handleBack() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SakuScreen(
        showBack: true,
        onBack: _handleBack,
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