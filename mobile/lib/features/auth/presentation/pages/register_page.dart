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

/// Figma "3 · Registrasi akun" (FE-01: FR-01, FR-02).
///
/// Validasi klien memakai [SakuValidators]; setelah tombol ditekan sekali,
/// field divalidasi ulang setiap diketik.
/// Terkirim ke `POST /auth/register` lewat [AuthRepository]; error server
/// (`error.details[].field`, 409 email terdaftar) tampil di field terkait.
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

  String _role = 'Pelanggan';
  bool _agree = true;
  bool _submitted = false;
  bool _busy = false;

  /// Error dari server per field API (`nama`, `email`, `kata_sandi`).
  Map<String, String> _serverErrors = const {};

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm, _domicile]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _serverErrors = const {};
    });
    final fieldsValid = _formKey.currentState!.validate();
    if (!fieldsValid || !_agree) return;
    final deps = AppScope.of(context);
    final auth = deps.authRepository;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final authSession = await auth.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
      // Sinkronkan juga ke AuthSession.instance agar modul Escrow tetap terbaca
      AuthSession.instance.save(
        token: authSession.token,
        id: authSession.user.id,
        name: authSession.user.name,
        userEmail: authSession.user.email,
        userRole: _role,
      );
      if (!mounted) return;
      SakuMotion.tick();
      navigator.pushReplacementNamed(AppRoutes.profileSetup);
    } on ApiException catch (e) {
      if (!mounted) return;
      final errors = {...e.fieldErrors};
      if (e.code == 'EMAIL_ALREADY_EXISTS') errors['email'] = e.message;
      if (errors.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
      setState(() => _serverErrors = errors);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field)) {
      setState(() => _serverErrors = {..._serverErrors}..remove(field));
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daftar Sebagai', style: AppTypography.body),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Pelanggan')),
                      selected: _role == 'Pelanggan',
                      onSelected: _busy
                          ? null
                          : (_) => setState(() => _role = 'Pelanggan'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Penyedia Jasa')),
                      selected: _role == 'Penyedia Jasa',
                      onSelected: _busy
                          ? null
                          : (_) => setState(() => _role = 'Penyedia Jasa'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SakuTextField(
            fieldKey: const Key('register-name'),
            controller: _name,
            label: 'Nama Lengkap',
            hint: 'Salma Nur Oktavia',
            textInputAction: TextInputAction.next,
            errorText: _serverErrors['nama'],
            onChanged: (_) => _clearServerError('nama'),
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
            errorText: _serverErrors['email'],
            onChanged: (_) => _clearServerError('email'),
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
            errorText: _serverErrors['kata_sandi'],
            onChanged: (_) => _clearServerError('kata_sandi'),
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
            label: _busy ? 'Memproses…' : 'Daftar Akun Baru',
            onPressed: _busy ? null : _submit,
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
