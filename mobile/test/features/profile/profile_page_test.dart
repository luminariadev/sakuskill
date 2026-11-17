import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuskill/app.dart';
import 'package:sakuskill/core/di/app_dependencies.dart';
import 'package:sakuskill/core/navigation/app_router.dart';
import 'package:sakuskill/features/auth/data/auth_session.dart';

void main() {
  setUp(() {
    AuthSession.instance.save(
      token: 'fake-jwt-token',
      id: 'test-user-id',
      name: 'Salma Nur Oktavia',
      userEmail: 'salma@gmail.com',
      userRole: 'Mahasiswa Dual-Mode',
    );
  });

  tearDown(() {
    AuthSession.instance.clear();
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      SakuSkillApp(
        dependencies: AppDependencies.offline(),
        initialRoute: AppRoutes.profile,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Halaman Profil: identitas, status verifikasi KTM, dan menu tampil',
      (tester) async {
    await pumpProfile(tester);

    expect(find.text('Profil & Akun'), findsOneWidget);
    expect(find.text('Salma Nur Oktavia'), findsOneWidget);
    expect(find.text('salma@gmail.com'), findsOneWidget);
    expect(find.text('KTM Terverifikasi · UIN Sunan Gunung Djati Bandung'), findsOneWidget);
    expect(find.text('Saldo Escrow'), findsOneWidget);
    expect(find.text('Lengkapi & Edit Profil'), findsOneWidget);
    expect(find.text('Kelola Jasa Saya'), findsOneWidget);
    expect(find.text('Riwayat Smart Barter'), findsOneWidget);
    expect(find.text('Keluar dari Akun'), findsOneWidget);
  });

  testWidgets('Logout: dialog konfirmasi membatalkan atau membersihkan sesi',
      (tester) async {
    await pumpProfile(tester);

    // Tekan tombol Keluar
    await tester.ensureVisible(find.byKey(const Key('profile-logout-button')));
    await tester.tap(find.byKey(const Key('profile-logout-button')));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi Keluar Akun'), findsOneWidget);
    expect(
      find.text('Apakah Anda yakin ingin keluar dari akun SakuSkill pada perangkat ini?'),
      findsOneWidget,
    );

    // Batal terlebih dahulu
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(AuthSession.instance.isLoggedIn, isTrue);

    // Tekan Keluar lagi lalu konfirmasi
    await tester.tap(find.byKey(const Key('profile-logout-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();

    // Sesi terhapus dan kembali ke Login
    expect(AuthSession.instance.isLoggedIn, isFalse);
    expect(find.text('Selamat Datang\nKembali'), findsOneWidget);
  });
}
