import 'package:material_ui/material_ui.dart';

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
/// TODO(anggota-5): sambungkan ke autentikasi backend. Untuk sekarang
/// validasi lokal: email/No. WA terisi dan kata sandi ≥ 8 karakter.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
    final ok = _id.text.trim().isNotEmpty && _password.text.length >= 8;
    if (!ok) {
      setState(() => _failed = true);
      return;
    }
    SakuMotion.tick();
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.shell, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return SakuScreen(
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
                  content: Text('Tautan reset dikirim ke email / WhatsApp Anda.'),
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
            const SnackBar(content: Text('Masuk dengan Google segera hadir.')),
          ),
        ),
        SakuTextLink(
          'Belum memiliki akun? Daftar Akun Baru di sini',
          onTap: () => Navigator.of(context)
              .pushReplacementNamed(AppRoutes.register),
        ),
      ],
    );
  }
}
