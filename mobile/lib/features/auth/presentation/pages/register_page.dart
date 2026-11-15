import 'package:material_ui/material_ui.dart';

import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';

/// Figma "3 · Registrasi akun".
///
/// TODO(anggota-5): kirim ke endpoint registrasi. Validasi lokal di bawah.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _domicile = TextEditingController();
  bool _agree = true;
  bool _submitted = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm, _domicile]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _err(String? message) => _submitted ? message : null;

  String? get _nameError =>
      _name.text.trim().isEmpty ? 'Nama lengkap wajib diisi' : null;
  String? get _emailError =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())
          ? null
          : 'Format email belum benar';
  String? get _phoneError =>
      RegExp(r'^0\d{9,13}$').hasMatch(_phone.text.trim())
          ? null
          : 'Nomor WhatsApp diawali 0, 10–14 digit';
  String? get _passwordError =>
      _password.text.length >= 8 ? null : 'Minimal 8 karakter';
  String? get _confirmError =>
      _confirm.text == _password.text && _confirm.text.isNotEmpty
          ? null
          : 'Kata sandi belum sama';

  void _submit() {
    setState(() => _submitted = true);
    final valid = [
          _nameError,
          _emailError,
          _phoneError,
          _passwordError,
          _confirmError,
        ].every((e) => e == null) &&
        _agree;
    if (!valid) return;
    SakuMotion.tick();
    Navigator.of(context).pushReplacementNamed(AppRoutes.profileSetup);
  }

  @override
  Widget build(BuildContext context) {
    void refresh(String _) {
      if (_submitted) setState(() {});
    }

    return SakuScreen(
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
          errorText: _err(_nameError),
          onChanged: refresh,
        ),
        SakuTextField(
          fieldKey: const Key('register-email'),
          controller: _email,
          label: 'Alamat Email',
          hint: 'salma@gmail.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: _err(_emailError),
          onChanged: refresh,
        ),
        SakuTextField(
          fieldKey: const Key('register-phone'),
          controller: _phone,
          label: 'Nomor WhatsApp Aktif',
          hint: '081223456789',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          errorText: _err(_phoneError),
          onChanged: refresh,
        ),
        SakuTextField(
          fieldKey: const Key('register-password'),
          controller: _password,
          label: 'Kata Sandi',
          hint: 'Minimal 8 karakter',
          obscure: true,
          textInputAction: TextInputAction.next,
          errorText: _err(_passwordError),
          onChanged: refresh,
        ),
        SakuTextField(
          fieldKey: const Key('register-confirm'),
          controller: _confirm,
          label: 'Konfirmasi Kata Sandi',
          hint: 'Ulangi kata sandi Anda',
          obscure: true,
          textInputAction: TextInputAction.next,
          errorText: _err(_confirmError),
          onChanged: refresh,
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
          label: 'Saya menyetujui Ketentuan Layanan Rekening Bersama Escrow & '
              'Sistem Transaksi SakuSkill.',
          color: _submitted && !_agree
              ? AppColors.danger
              : AppColors.textSecondary,
        ),
        SakuButton(
          key: const Key('register-submit'),
          label: 'Daftar Akun Baru',
          onPressed: _submit,
        ),
        SakuTextLink(
          'Sudah memiliki akun? Masuk di sini',
          onTap: () =>
              Navigator.of(context).pushReplacementNamed(AppRoutes.login),
        ),
      ],
    );
  }
}
