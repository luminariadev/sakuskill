import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuskill/app.dart';
import 'package:sakuskill/core/di/app_dependencies.dart';
import 'package:sakuskill/core/navigation/app_router.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, String route) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      SakuSkillApp(dependencies: AppDependencies.offline(), initialRoute: route),
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
}
