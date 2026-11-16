import 'package:flutter/material.dart';

import '../../../../core/motion/saku_motion.dart';
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
/// TODO(anggota-5): ganti simulasi kredensial di [_submit] dengan
/// `POST /auth/login` (M2). Sementara: sandi < 8 karakter dianggap salah.
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

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _failed = false);
    if (!_formKey.currentState!.validate()) return;
    // Simulasi respons server sampai repository auth tersedia (M2).
    final credentialsOk =
        _password.text.length >= SakuValidators.passwordMinLength;
    if (!credentialsOk) {
      setState(() => _failed = true);
      return;
    }
    SakuMotion.tick();
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
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
            label: 'Masuk Sekarang',
            onPressed: _submit,
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
                    text: 'Email atau kata sandi tidak sesuai. Silakan coba lagi.',
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
