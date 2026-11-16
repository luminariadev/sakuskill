import 'package:flutter/material.dart';

import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';

/// Figma "3 · Registrasi akun" (FE-01: FR-01, FR-02).
///
/// Validasi klien memakai [SakuValidators]; setelah tombol ditekan sekali,
/// field divalidasi ulang setiap diketik.
/// TODO(anggota-5): kirim ke `POST /auth/register` dan petakan
/// `error.details[].field` ke `errorText` field terkait.
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

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm, _domicile]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);
    final fieldsValid = _formKey.currentState!.validate();
    if (!fieldsValid || !_agree) return;
    SakuMotion.tick();
    Navigator.of(context).pushReplacementNamed(AppRoutes.profileSetup);
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
      ),
    );
  }
}
