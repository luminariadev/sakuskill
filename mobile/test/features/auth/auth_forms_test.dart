import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sakuskill/app.dart';
import 'package:sakuskill/core/di/app_dependencies.dart';
import 'package:sakuskill/core/navigation/app_router.dart';
import 'package:sakuskill/core/network/api_exception.dart';
import 'package:sakuskill/core/storage/session_store.dart' as secure;
import 'package:sakuskill/features/auth/data/auth_repository.dart';
import 'package:sakuskill/features/auth/data/auth_session.dart' as app_session;

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.onRegister);

  Future<secure.AuthSession> Function() onRegister;

  @override
  Future<secure.AuthSession> login({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<secure.AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? bio,
  }) =>
      onRegister();

  @override
  Future<void> logout() async {}
}

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    String route, {
    AuthRepository? authRepository,
  }) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      SakuSkillApp(
        dependencies: AppDependencies.offline(authRepository: authRepository),
        initialRoute: route,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapSubmit(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  testWidgets('Registrasi: error per field lalu lolos ke Setup profil',
      (tester) async {
    await pumpAt(tester, AppRoutes.register);

    await tapSubmit(tester, const Key('register-submit'));
    expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Nomor WhatsApp wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    expect(find.text('Konfirmasi kata sandi wajib diisi'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('register-name')), 'Salma Nur Oktavia');
    await tester.enterText(find.byKey(const Key('register-email')), 'salma@gmail');
    await tester.enterText(find.byKey(const Key('register-phone')), '081223456789');
    await tester.enterText(find.byKey(const Key('register-password')), 'rahasia1');
    await tester.enterText(find.byKey(const Key('register-confirm')), 'rahasia2');
    await tester.pumpAndSettle();

    // Setelah submit pertama, validasi berjalan saat mengetik.
    expect(find.text('Format email belum benar'), findsOneWidget);
    expect(find.text('Kata sandi belum sama'), findsOneWidget);
    expect(find.text('Nama lengkap wajib diisi'), findsNothing);

    await tester.enterText(find.byKey(const Key('register-email')), 'salma@gmail.com');
    await tester.enterText(find.byKey(const Key('register-confirm')), 'rahasia1');
    await tapSubmit(tester, const Key('register-submit'));

    expect(find.text('Lengkapi Profil\n& Portofolio'), findsOneWidget);
  });

  testWidgets('Login: field kosong ditolak validator tanpa kotak eror generik',
      (tester) async {
    await pumpAt(tester, AppRoutes.login);

    await tapSubmit(tester, const Key('login-submit'));
    expect(find.text('Email / No. WhatsApp wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-error')), findsNothing);
  });

  testWidgets('Tombol kembali di Login (saat root) kembali ke Awalan',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await pumpAt(tester, AppRoutes.login);
    await tapSubmit(tester, const Key('back-arrow-button'));
    expect(find.text('Masuk ke Akun Anda'), findsOneWidget);
  });

  testWidgets('Tombol kembali di Register (saat root) kembali ke Awalan',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await pumpAt(tester, AppRoutes.register);
    await tapSubmit(tester, const Key('back-arrow-button'));
    expect(find.text('Masuk ke Akun Anda'), findsOneWidget);
  });

  testWidgets('Setup profil: tautan portofolio harus https', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpAt(tester, AppRoutes.profileSetup);

    await tester.enterText(
        find.byKey(const Key('profile-link')), 'http://behance.net/salma');
    await tester.pumpAndSettle();
    expect(find.text('Tautan harus diawali https:// dan valid'), findsOneWidget);

    await tapSubmit(tester, const Key('profile-save'));
    expect(find.text('Lengkapi Profil\n& Portofolio'), findsOneWidget); // tetap

    await tester.enterText(find.byKey(const Key('profile-link')), '');
    await tapSubmit(tester, const Key('profile-save'));
    expect(find.text('Temukan keahlian di sekitarmu'), findsOneWidget); // opsional
  });

  testWidgets(
      'Registrasi: error 422 per-field dan 409 email tampil inline lalu hilang saat diubah',
      (tester) async {
    late ApiException errorToThrow;
    errorToThrow = const ApiException(
      code: ApiException.validationError,
      message: 'Data pendaftaran belum valid.',
      statusCode: 422,
      fieldErrors: {
        'nama': 'Nama minimal 3 huruf (server)',
        'email': 'Domain email belum didukung (server)',
        'kata_sandi': 'Sandi terlalu lemah (server)',
      },
    );
    final repo = _FakeAuthRepository(() => Future.error(errorToThrow));

    await pumpAt(tester, AppRoutes.register, authRepository: repo);

    await tester.enterText(find.byKey(const Key('register-name')), 'Salma Nur');
    await tester.enterText(find.byKey(const Key('register-email')), 'salma@uin.ac.id');
    await tester.enterText(find.byKey(const Key('register-phone')), '081223456789');
    await tester.enterText(find.byKey(const Key('register-password')), 'rahasia123');
    await tester.enterText(find.byKey(const Key('register-confirm')), 'rahasia123');
    await tapSubmit(tester, const Key('register-submit'));

    expect(find.text('Nama minimal 3 huruf (server)'), findsOneWidget);
    expect(find.text('Domain email belum didukung (server)'), findsOneWidget);
    expect(find.text('Sandi terlalu lemah (server)'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('register-name')),
      'Salma Nur Oktavia',
    );
    await tester.pumpAndSettle();
    expect(find.text('Nama minimal 3 huruf (server)'), findsNothing);
    expect(find.text('Domain email belum didukung (server)'), findsOneWidget);

    errorToThrow = const ApiException(
      code: 'EMAIL_ALREADY_EXISTS',
      message: 'Email sudah terdaftar di SakuSkill.',
      statusCode: 409,
    );
    await tapSubmit(tester, const Key('register-submit'));

    expect(find.text('Email sudah terdaftar di SakuSkill.'), findsOneWidget);
    expect(find.text('Sandi terlalu lemah (server)'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('register-email')),
      'salma.baru@uin.ac.id',
    );
    await tester.pumpAndSettle();
    expect(find.text('Email sudah terdaftar di SakuSkill.'), findsNothing);
  });

  testWidgets('401 global menghapus sesi dan mengarahkan ke Login dengan SnackBar',
      (tester) async {
    addTearDown(app_session.AuthSession.instance.clear);
    await pumpAt(tester, AppRoutes.shell);

    app_session.AuthSession.instance.save(
      token: 'expired-jwt',
      id: 'u-1',
      name: 'Salma',
    );
    expect(app_session.AuthSession.instance.isLoggedIn, isTrue);

    app_session.AuthSession.instance.notifyUnauthorized();
    await tester.pumpAndSettle();

    expect(app_session.AuthSession.instance.isLoggedIn, isFalse);
    expect(
      find.text('Sesi Anda telah berakhir. Silakan masuk kembali.'),
      findsOneWidget,
    );
    expect(find.text('Selamat Datang\nKembali'), findsOneWidget);
  });
}
