import 'package:flutter/material.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../../core/motion/saku_motion.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/state/account_finance_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/saku_buttons.dart';
import '../../../../core/widgets/saku_form.dart';
import '../../../../core/widgets/saku_screen.dart';

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
  Map<String, String> _serverErrors = const {};

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm, _domicile]) {
      c.dispose();
    }
    super.dispose();
  }

  void _clearServerError(String field) {
    if (!_serverErrors.containsKey(field)) return;
    setState(() {
      _serverErrors = Map<String, String>.from(_serverErrors)..remove(field);
    });
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() {
      _submitted = true;
      _authError = null;
      _serverErrors = const {};
    });

    final fieldsValid = _formKey.currentState!.validate();
    if (!fieldsValid || !_agree) return;

    final auth = AppScope.of(context).authRepository;
    final navigator = Navigator.of(context);
    setState(() => _loading = true);

    try {
      final phone = _phone.text.trim();
      final domicile = _domicile.text.trim();
      final profileNotes = [
        if (phone.isNotEmpty) 'WA: $phone',
        if (domicile.isNotEmpty) 'Domisili: $domicile',
      ].join(' · ');

      await auth.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        bio: profileNotes.isEmpty ? null : profileNotes,
      );

      if (!mounted) return;
      AccountFinanceStore.instance.resetForLogout();
      SakuMotion.tick();
      navigator.pushReplacementNamed(AppRoutes.profileSetup);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'EMAIL_ALREADY_EXISTS') {
          _serverErrors = {'email': e.message};
        } else if (e.fieldErrors.isNotEmpty) {
          _serverErrors = Map<String, String>.from(e.fieldErrors);
        } else {
          _authError = e.message;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _authError =
            'Gagal terhubung ke server. Periksa koneksi internet Anda lalu coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
      autovalidateMode: _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: SakuScreen(
        showBack: true,
        onBack: _handleBack,
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