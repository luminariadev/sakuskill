import 'package:flutter/material.dart';

import '../../data/auth_session.dart';
import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';
import '../../../../core/widgets/saku_surfaces.dart';

/// Figma "2 · Login pengguna".
///
/// Validasi klien (FE-02): kedua field wajib diisi lewat [SakuValidators].
/// Kegagalan kredensial tampil sebagai pesan generik di kotak merah (FR-05),
/// tanpa menyebut field mana yang salah.
///
/// Terhubung ke `POST /auth/login` lewat [AuthRepository]; mode demo/offline
/// memakai [DemoAuthRepository] (sandi < 8 karakter dianggap salah).
/// Backend saat ini hanya menerima email (belum No. WhatsApp).
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
  bool _busy = false;
  static const String _errorMessage =
      'Email atau kata sandi tidak sesuai. Silakan coba lagi.';

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _failed = false);
    if (!_formKey.currentState!.validate()) return;
    final deps = AppScope.of(context);
    final auth = deps.authRepository;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final authSession = await auth.login(
        email: _id.text,
        password: _password.text,
      );
      // Sinkronkan juga ke AuthSession.instance agar modul Escrow tetap terbaca
      AuthSession.instance.save(
        token: authSession.token,
        id: authSession.user.id,
        name: authSession.user.name,
        userEmail: authSession.user.email,
      );
      if (!mounted) return;
      SakuMotion.tick();
      navigator.pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isConnectivity || e.code == ApiException.invalidResponseError) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      } else {
        // 401 kredensial salah / 422 format: pesan generik (FR-05).
        setState(() => _failed = true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
            label: _busy ? 'Memproses…' : 'Masuk Sekarang',
            onPressed: _busy ? null : _submit,
          ),
          AnimatedSwitcher(
            duration: SakuMotion.base,
            transitionBuilder: (child, a) => SizeTransition(
              sizeFactor: a,
              child: FadeTransition(opacity: a, child: child),
            ),
            child: _failed
                ? const InfoBox(
                    key: ValueKey('login-error'),
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
