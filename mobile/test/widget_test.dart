import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sakuskill/app.dart';
import 'package:sakuskill/core/di/app_dependencies.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      SakuSkillApp(dependencies: AppDependencies.offline()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Beranda menampilkan lokasi, saldo, banner & feed terdekat',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('Cibiru, Bandung'), findsOneWidget);
    expect(find.text('Saldo Rp 150.000'), findsOneWidget);
    expect(find.textContaining('Aman dari awal'), findsOneWidget);
    expect(find.text('Keahlian di sekitarmu'), findsOneWidget);
    expect(find.text('Rifqi Hamdani'), findsOneWidget);
    expect(find.text('Ahmad Fauzi'), findsOneWidget);

    // Navigasi utama: 5 tab sesuai Figma.
    for (final tab in ['home', 'explore', 'orders', 'barter', 'profile']) {
      expect(find.byKey(Key('nav-$tab')), findsOneWidget);
    }
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('Chip 4.8+ menyembunyikan penyedia dengan rating < 4.8',
      (tester) async {
    await pumpApp(tester);
    expect(find.text('Sarah Aulia'), findsOneWidget); // rating 4.7

    await tester.tap(find.byKey(const Key('filter-rating')));
    await tester.pumpAndSettle();

    expect(find.text('Sarah Aulia'), findsNothing);
    expect(find.text('Rifqi Hamdani'), findsOneWidget); // rating 4.9
  });

  testWidgets('Kartu layanan membuka Detail layanan dengan bar aksi',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Ahmad Fauzi'));
    await tester.pumpAndSettle();

    expect(find.text('Tentang layanan'), findsOneWidget);
    expect(find.text('Menerima Barter'), findsOneWidget);
    expect(find.byKey(const Key('detail-chat')), findsOneWidget);
    expect(find.byKey(const Key('detail-barter')), findsOneWidget);
    expect(find.textContaining('Order via Escrow'), findsOneWidget);
  });

  testWidgets('Filter Smart Barter menyembunyikan jasa berbayar saja',
      (tester) async {
    await pumpApp(tester);
    expect(find.text('Sarah Aulia'), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-barter')));
    await tester.pumpAndSettle();

    expect(find.text('Sarah Aulia'), findsNothing);
    expect(find.text('Rifqi Hamdani'), findsOneWidget);
  });

  testWidgets('Filter kategori Fotografi', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('category-Fotografi')));
    await tester.pumpAndSettle();

    expect(find.text('Dina Rahmawati'), findsOneWidget);
    expect(find.text('Ahmad Fauzi'), findsNothing);
  });

  testWidgets('Halaman pencarian memfilter berdasarkan kata kunci',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('home-search-field')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('search-input')), 'laptop');
    await tester.pump(const Duration(milliseconds: 350)); // debounce
    await tester.pumpAndSettle();

    expect(find.text('Rifqi Hamdani'), findsOneWidget);
    expect(find.text('Dina Rahmawati'), findsNothing);
  });
}
