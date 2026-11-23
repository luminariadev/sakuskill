import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sakuskill/app.dart';
import 'package:sakuskill/core/di/app_dependencies.dart';
import 'package:sakuskill/core/navigation/app_router.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    String initialRoute = AppRoutes.shell,
  }) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      SakuSkillApp(
        dependencies: AppDependencies.offline(),
        initialRoute: initialRoute,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('Awalan → Login → Beranda (mode kurangi animasi)', (tester) async {
    // Ilustrasi Awalan melayang terus-menerus; dengan "kurangi animasi"
    // aktif, animasinya harus berhenti sehingga layar bisa "settle".
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await pumpApp(tester, initialRoute: AppRoutes.welcome);
    expect(find.text('Masuk ke Akun Anda'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('welcome-login')));
    expect(find.text('Selamat Datang\nKembali'), findsOneWidget);

    // Kata sandi < 8 karakter → kotak eror tampil.
    await tester.enterText(find.byKey(const Key('login-id')), 'salma@gmail.com');
    await tester.enterText(find.byKey(const Key('login-password')), '123');
    await tapAndSettle(tester, find.byKey(const Key('login-submit')));
    expect(find.byKey(const ValueKey('login-error')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login-password')), 'rahasia123');
    await tapAndSettle(tester, find.byKey(const Key('login-submit')));
    expect(find.text('Temukan keahlian di sekitarmu'), findsOneWidget);
  });

  testWidgets('Beranda: saldo, banner escrow, feed & navigasi baru',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('Rp 250.000'), findsOneWidget);
    expect(find.text('Dana Aman Rekening Bersama Escrow'), findsOneWidget);
    expect(find.text('Temukan keahlian di sekitarmu'), findsOneWidget);
    expect(find.text('Salma Nur Oktavia'), findsOneWidget);
    expect(find.text('Rifqi Hamdani'), findsOneWidget);

    for (final tab in ['home', 'explore', 'create', 'chat', 'activity']) {
      expect(find.byKey(Key('nav-$tab')), findsOneWidget);
    }
  });

  testWidgets('Chip Kebutuhan Proyek hanya menampilkan permintaan',
      (tester) async {
    await pumpApp(tester);

    await tapAndSettle(tester, find.byKey(const Key('filter-request')));

    expect(find.text('Dicari: Desain Spanduk 3×1 Meter Siap Cetak'), findsOneWidget);
    expect(find.text('Rifqi Hamdani'), findsNothing);
  });

  testWidgets('Filter Smart Barter menyembunyikan jasa berbayar saja',
      (tester) async {
    await pumpApp(tester);
    expect(find.text('Sarah Aulia'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('filter-barter')));

    expect(find.text('Sarah Aulia'), findsNothing);
    expect(find.text('Rizkia Nuari'), findsOneWidget);
  });

  testWidgets('Kartu membuka Detail layanan dengan aksi Chat & Pesan',
      (tester) async {
    await pumpApp(tester);

    await tapAndSettle(tester, find.text('Jasa Desain Feed IG & Spanduk Toko'));

    expect(find.text('Detail Layanan Jasa'), findsOneWidget);
    expect(find.text('Deskripsi & Cakupan Brief'), findsOneWidget);
    expect(find.byKey(const Key('detail-chat')), findsOneWidget);
    expect(find.textContaining('Buat Pesanan'), findsOneWidget);
  });

  testWidgets('Tombol + membuka menu aksi cepat → buat penawaran barter',
      (tester) async {
    await pumpApp(tester);

    await tapAndSettle(tester, find.byKey(const Key('nav-create')));
    expect(find.text('Buat Aktivitas Baru'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('quick-barter')));
    expect(find.text('Buat Penawaran\nBarter Baru'), findsOneWidget);
  });

  testWidgets('Alur escrow: pesan → terima → setujui → bayar → tracking',
      (tester) async {
    await pumpApp(tester, initialRoute: AppRoutes.orderService);

    await tapAndSettle(tester, find.byKey(const Key('order-submit')));
    expect(find.text('Pesanan Baru Masuk'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('incoming-accept')));
    expect(find.text('DRAFT KESEPAKATAN'), findsOneWidget);

    // Kirim pesan chat → muncul sebagai gelembung baru.
    await tester.enterText(find.byKey(const Key('chat-input')), 'Siap, terima kasih!');
    await tapAndSettle(tester, find.byKey(const Key('chat-send')));
    expect(find.text('Siap, terima kasih!'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('chat-agree')));
    expect(find.text('Pembayaran\nRekening Bersama'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('payment-submit')));
    expect(find.textContaining('STATUS: DIKERJAKAN'), findsOneWidget);
  });

  testWidgets('Tab Chat & Aktivitas menampilkan transaksi demo', (tester) async {
    await pumpApp(tester);

    await tapAndSettle(tester, find.byKey(const Key('nav-chat')));
    expect(find.text('Pesan & Diskusi'), findsOneWidget);
    expect(find.text('KONTRAK BARTER #BTR-012'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('nav-activity')));
    expect(find.text('Aktivitas Saya'), findsOneWidget);
    expect(find.textContaining('Belum ada pesanan jasa atau transaksi escrow aktif saat ini.'), findsOneWidget);
  });

  testWidgets('Halaman pencarian memfilter berdasarkan kata kunci',
      (tester) async {
    await pumpApp(tester);

    await tapAndSettle(tester, find.byKey(const Key('home-search-field')));

    await tester.enterText(find.byKey(const Key('search-input')), 'laptop');
    await tester.pump(const Duration(milliseconds: 350)); // debounce
    await tester.pumpAndSettle();

    expect(find.text('Rifqi Hamdani'), findsOneWidget);
    expect(find.text('Dina Rahmawati'), findsNothing);
  });
}
