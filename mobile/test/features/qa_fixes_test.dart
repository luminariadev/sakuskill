import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuskill/app.dart';
import 'package:sakuskill/core/config/app_config.dart';
import 'package:sakuskill/core/di/app_dependencies.dart';
import 'package:sakuskill/core/navigation/app_router.dart';
import 'package:sakuskill/core/state/account_finance_store.dart';
import 'package:sakuskill/core/widgets/saku_form.dart';
import 'package:sakuskill/features/auth/data/auth_session.dart';
import 'package:sakuskill/features/auth/presentation/pages/profile_setup_page.dart';
import 'package:sakuskill/features/barter/data/datasources/barter_remote_data_source.dart';
import 'package:sakuskill/features/barter/data/models/barter_model.dart';
import 'package:sakuskill/features/barter/presentation/pages/barter_done_page.dart';
import 'package:sakuskill/features/barter/presentation/pages/barter_propose_page.dart';
import 'package:sakuskill/features/barter/presentation/pages/barter_workroom_page.dart';
import 'package:sakuskill/features/complaint/presentation/pages/complaint_page.dart';
import 'package:sakuskill/features/complaint/presentation/pages/help_center_page.dart';
import 'package:sakuskill/features/discovery/domain/entities/service_listing.dart';
import 'package:sakuskill/features/discovery/presentation/pages/service_detail_page.dart';
import 'package:sakuskill/features/escrow/data/models/escrow_order_model.dart';
import 'package:sakuskill/features/escrow/presentation/pages/escrow_payment_page.dart';
import 'package:sakuskill/features/escrow/presentation/pages/order_chat_page.dart';
import 'package:sakuskill/features/escrow/presentation/pages/order_create_page.dart';
import 'package:sakuskill/features/wallet/presentation/pages/wallet_page.dart';

void main() {
  test('AccountFinanceStore: akun baru live mulai Rp 0, sinkron & withdraw simulasi bekerja', () {
    final store = AccountFinanceStore.forTest(useMock: false);
    expect(store.availableBalance, 0);
    expect(store.escrowHeld, 0);
    expect(store.activeOrderCount, 0);
    expect(store.myServiceCount, 0);
    expect(store.mutations, isEmpty);

    // Gagal tarik jika saldo 0
    expect(
      store.simulateWithdraw(
        amount: 25000,
        methodLabel: 'Transfer Bank',
        destinationAccount: '13100123456',
      ),
      contains('Rp 0'),
    );

    // Sinkron dengan 1 order penyedia selesai (Rp 75.000) + 1 order berjalan ditahan (Rp 50.000)
    store.syncFromOrders(
      userId: 'user-qa-1',
      providerOrders: const [
        EscrowOrderModel(
          orderId: 'ord-done-1',
          kodePesanan: '#SK-101',
          judulLayanan: 'Desain UI Landing Page',
          statusPesanan: 'Selesai',
          statusEscrow: 'Dilepas',
          statusKode: 'completed',
          harga: 75000,
          stepperTahap: 3,
          bolehLanjutInProgress: true,
        ),
      ],
      customerOrders: const [
        EscrowOrderModel(
          orderId: 'ord-active-2',
          kodePesanan: '#SK-102',
          judulLayanan: 'Install Ulang Windows',
          statusPesanan: 'Dikerjakan',
          statusEscrow: 'Ditahan (Simulasi)',
          statusKode: 'in_progress',
          harga: 50000,
          stepperTahap: 1,
          bolehLanjutInProgress: true,
        ),
      ],
    );

    expect(store.availableBalance, 75000);
    expect(store.escrowHeld, 50000);
    expect(store.activeOrderCount, 1);
    expect(store.mutations.length, 2);

    // Penarikan valid
    final err = store.simulateWithdraw(
      amount: 25000,
      methodLabel: 'E-Wallet',
      destinationAccount: '081234567890',
    );
    expect(err, isNull);
    expect(store.availableBalance, 50000);
    expect(store.mutations.first.title, 'Penarikan Dana (Simulasi)');
    expect(store.mutations.first.amountLabel, '-Rp 25.000');

    // Reset saat logout
    store.resetForLogout();
    expect(store.availableBalance, 0);
    expect(store.escrowHeld, 0);
    expect(store.mutations, isEmpty);
  });

  testWidgets('LoginPage tidak menampilkan tombol Google yang tidak aktif',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      SakuSkillApp(
        dependencies: AppDependencies.offline(),
        initialRoute: AppRoutes.login,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Lanjutkan dengan Akun Google'), findsNothing);
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
  });

  testWidgets(
      'ServiceDetailPage: Bagikan/Simpan dihapus & layanan hybrid punya CTA Pesan + Barter',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const listing = ServiceListing(
      id: 'gig-hybrid-1',
      title: 'Jasa Desain Poster & Feed UMKM',
      description: 'Desain profesional siap cetak & sosial media.',
      offerType: OfferType.paidAndBarter,
      providerName: 'Rizkia Nuari',
      skillName: 'Desain Grafis',
      category: 'Desain',
      price: 75000,
      barterWant: 'Jasa Video Reels',
      deliveryDays: 2,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ServiceDetailPage(listing: listing),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bagikan'), findsNothing);
    expect(find.text('Simpan'), findsNothing);
    expect(find.byKey(const Key('detail-save')), findsNothing);
    expect(find.byKey(const Key('detail-order')), findsOneWidget);
    expect(find.byKey(const Key('detail-barter')), findsOneWidget);
  });

  testWidgets('OrderCreatePage: dropzone berkas palsu dihapus dan diganti tautan opsional',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      SakuSkillApp(
        dependencies: AppDependencies.offline(),
        initialRoute: AppRoutes.orderService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unggah Berkas Aset'), findsNothing);
    expect(find.byType(OrderCreatePage), findsOneWidget);
    expect(find.byKey(const Key('order-ref-link')), findsOneWidget);
  });

  testWidgets('WelcomePage: statis menyatu background, tanpa teks escrow dan hanya tombol masuk/daftar',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      SakuSkillApp(
        dependencies: AppDependencies.offline(),
        initialRoute: AppRoutes.welcome,
      ),
    );
    // Jika animasi naik-turun kontinyu sudah dihapus, pumpAndSettle selesai tanpa timeout.
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('welcome-login')), findsOneWidget);
    expect(find.byKey(const Key('welcome-register')), findsOneWidget);
    expect(find.text('Dana Aman Rekening Bersama Escrow'), findsNothing);
    expect(find.text('Tukar Keahlian Tanpa Uang Tunai'), findsNothing);
    expect(find.text('Talenta Terdekat Sekitar Kampus Cibiru'), findsNothing);
  });

  testWidgets('OrderChatPage: penyedia melihat tombol Terima Pesanan, bukan Bayar Escrow',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AuthSession.instance.save(
      token: 'tok-tsalsa',
      id: 'tsalsa-id',
      name: 'Tsalsa Nur Faridhla',
      userEmail: 'tsalsa@gmail.com',
      userRole: 'Mahasiswa',
    );
    addTearDown(AuthSession.instance.clear);

    const order = EscrowOrderModel(
      orderId: 'ord-1',
      kodePesanan: 'ORD-BADA0C18',
      judulLayanan: 'Desain Canva',
      statusPesanan: 'Diajukan',
      statusEscrow: 'Belum Dibayar',
      harga: 50000,
      stepperTahap: 1,
      statusKode: 'requested',
      pelangganId: 'suci-id',
      penyediaId: 'tsalsa-id',
      namaLawanTransaksi: 'Suci Pratiwi',
      peranLawanTransaksi: 'Pelanggan',
    );

    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies.offline(),
        child: const MaterialApp(
          home: OrderChatPage(order: order),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('chat-provider-accept')), findsOneWidget);
    expect(find.text('Bayar & Kunci Dana di Escrow'), findsNothing);
  });

  testWidgets('EscrowPaymentPage: bersih dari sisa anotasi [cite: 4]', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies.offline(),
        child: const MaterialApp(home: EscrowPaymentPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('[cite: 4]'), findsNothing);
  });

  testWidgets('ComplaintPage & HelpCenterPage: bukti tautan HTTPS & FAQ tanpa Dimas',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: HelpCenterPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('PERTANYAAN UMUM (FAQ)'), findsOneWidget);
    expect(find.textContaining('Dimas'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(home: ComplaintPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unggah Bukti Pendukung'), findsNothing);
    expect(find.byKey(const Key('complaint-evidence-link')), findsOneWidget);
  });

  testWidgets('BarterDonePage: menampilkan nama mitra nyata untuk rating dua arah',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AuthSession.instance.save(
      token: 'tok-tsalsa',
      id: 'tsalsa-id',
      name: 'Tsalsa Nur Faridhla',
      userEmail: 'tsalsa@gmail.com',
      userRole: 'Mahasiswa',
    );
    addTearDown(AuthSession.instance.clear);

    final barter = BarterAgreementModel(
      id: '421b55c2-f8c9-41dc-b9d4-5c80b9ff8b6f',
      listingId: 'lst-1',
      pengajuId: 'tsalsa-id',
      penerimaId: 'suci-id',
      deskripsiJasaPengaju: 'Edit Video',
      deskripsiJasaPenerima: 'Layanan Fotografi',
      tenggatPekerjaan: DateTime(2026, 11, 28),
      setujuPengaju: true,
      setujuPenerima: true,
      konfirmasiSelesaiPengaju: true,
      konfirmasiSelesaiPenerima: true,
      status: 'Selesai',
      statusKode: 'completed',
      namaPengaju: 'Tsalsa Nur Faridhla',
      namaPenerima: 'Suci Pratiwi',
    );

    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies.offline(),
        child: MaterialApp(home: BarterDonePage(barter: barter)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Suci Pratiwi'), findsWidgets);
    expect(find.byKey(const Key('barter-done-submit')), findsOneWidget);
  });

  testWidgets('ProfileSetupPage: bebas dari preset bio & URL behance Salma',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AuthSession.instance.save(
      token: 'tok-ys',
      id: 'ys-id',
      name: 'Yusuf Santoso',
      userEmail: 'yusuf@gmail.com',
      userRole: 'Mahasiswa',
    );
    addTearDown(AuthSession.instance.clear);

    await tester.pumpWidget(
      const MaterialApp(home: ProfileSetupPage()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('salmanuroktavia'), findsNothing);
    expect(find.textContaining('Desainer grafis & ilustrator digital'), findsNothing);
    expect(find.text('YS'), findsOneWidget);
  });

  testWidgets('WalletPage: menampilkan desain clay/glass baru dan kontrol penarikan lengkap',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies.offline(),
        child: const MaterialApp(home: WalletPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TERPROTEKSI'), findsOneWidget);
    expect(find.text('Transfer Bank'), findsOneWidget);
    expect(find.text('E-Wallet'), findsOneWidget);
    expect(find.byKey(const Key('wallet-account-input')), findsOneWidget);
    expect(find.byKey(const Key('wallet-amount-input')), findsOneWidget);
    expect(find.byKey(const Key('wallet-fill-max')), findsOneWidget);
    expect(find.byKey(const Key('wallet-withdraw')), findsOneWidget);
  });

  testWidgets('ProfileSetupPage: pilih foto profil dari galeri & hapus foto',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Valid 1x1 transparent PNG bytes
    final samplePng = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    );

    AuthSession.instance.save(
      token: 'tok-aj',
      id: 'aj-id',
      name: 'Ahmad Jaenudin',
      userEmail: 'ahmad@gmail.com',
      userRole: 'Mahasiswa',
    );
    addTearDown(AuthSession.instance.clear);

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileSetupPage(
          pickPhoto: () async => samplePng,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pilih Foto dari Galeri'), findsOneWidget);
    expect(find.byKey(const Key('profile-remove-photo')), findsNothing);

    await tester.tap(find.byKey(const Key('profile-pick-photo')));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Ganti Foto'), findsOneWidget);
    expect(find.byKey(const Key('profile-remove-photo')), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-remove-photo')));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(find.text('Pilih Foto dari Galeri'), findsOneWidget);
    expect(find.text('AJ'), findsOneWidget);
  });

  testWidgets('BarterWorkroomPage: pengaju dapat membatalkan tawaran sebelum disepakati',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final fakeDs = _RecordingBarterDataSource();
    final draftBarter = BarterAgreementModel(
      id: 'btr-cancel-test',
      listingId: 'lst-1',
      pengajuId: 'aj-id',
      penerimaId: 'np-id',
      deskripsiJasaPengaju: 'Edit Design Canva',
      deskripsiJasaPenerima: 'Editing Reels Tiktok',
      tenggatPekerjaan: DateTime(2026, 12, 1),
      setujuPengaju: true,
      setujuPenerima: false,
      konfirmasiSelesaiPengaju: false,
      konfirmasiSelesaiPenerima: false,
      status: 'Diajukan',
      statusKode: 'requested',
      namaPengaju: 'Ahmad Jaenudin',
      namaPenerima: 'Nadia Pratiwi',
    );

    AuthSession.instance.save(
      token: 'tok-aj',
      id: 'aj-id',
      name: 'Ahmad Jaenudin',
      userEmail: 'ahmad@gmail.com',
      userRole: 'Mahasiswa',
    );
    addTearDown(AuthSession.instance.clear);

    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies.offline(barterDataSource: fakeDs),
        child: MaterialApp(home: BarterWorkroomPage(barter: draftBarter)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('barter-cancel')), findsOneWidget);
    expect(find.byKey(const Key('barter-reject')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('barter-cancel')));
    await tester.tap(find.byKey(const Key('barter-cancel')));
    await tester.pumpAndSettle();

    expect(fakeDs.cancelledIds, ['btr-cancel-test']);
    expect(fakeDs.rejectedIds, isEmpty);
    expect(find.byKey(const Key('barter-cancelled-banner')), findsOneWidget);

    // Sisi penerima melihat tombol Tolak Tawaran Barter (reject)
    AuthSession.instance.save(
      token: 'tok-np',
      id: 'np-id',
      name: 'Nadia Pratiwi',
      userEmail: 'nadia@gmail.com',
      userRole: 'Mahasiswa',
    );
    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies.offline(barterDataSource: fakeDs),
        child: MaterialApp(
          key: const ValueKey('receiver-view'),
          home: BarterWorkroomPage(barter: draftBarter),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('barter-reject')), findsOneWidget);
    expect(find.byKey(const Key('barter-cancel')), findsNothing);
  });

  test('matchBarterCandidates: memisahkan yang dicari vs barterWant & mendeteksi cocok 2 arah', () {
    const candidates = [
      ServiceListing(
        id: 'ui-ahmad',
        title: 'Design UI Mobile',
        description: 'Desain aplikasi online shop dengan Figma',
        offerType: OfferType.paidAndBarter,
        providerName: 'Ahmad Jaenudin',
        skillName: 'Desain UI/UX & Grafis Poster',
        category: 'Desain',
        barterWant: 'Editing Video Youtube 30 menit',
      ),
      ServiceListing(
        id: 'poster-nadia',
        title: 'Desain Poster UMKM Pro',
        description: 'Poster promosi UMKM cepat',
        offerType: OfferType.paidAndBarter,
        providerName: 'Nadia Pratiwi',
        skillName: 'Desain UI/UX & Grafis Poster',
        category: 'Desain',
        barterWant: 'Jasa Editing Video Reels',
      ),
      ServiceListing(
        id: 'video-sinta',
        title: 'Edit Video Reels & Shorts',
        description: 'Color grading dan cut dinamis video pendek',
        offerType: OfferType.barter,
        providerName: 'Sinta Lestari',
        skillName: 'Editing Video & Motion',
        category: 'Video',
        barterWant: 'Desain UI Mobile',
      ),
    ];

    // Cari "Editing Video" TIDAK boleh mencocokkan Design UI Mobile yang hanya MENCARI Editing Video
    final searchVideo = matchBarterCandidates(
      candidates: candidates,
      needQuery: 'Editing Video',
      currentUserName: 'Fadillah Ananda',
    );
    expect(searchVideo.map((m) => m.listing.id).toList(), ['video-sinta']);

    // Cari "Desain" dengan tawaran "Editing Video" harus menandai Cocok 2 Arah pada Desain
    final searchMutual = matchBarterCandidates(
      candidates: candidates,
      needQuery: 'Desain',
      offerQuery: 'Editing Video',
      currentUserName: 'Ahmad Jaenudin',
    );
    expect(searchMutual.map((m) => m.listing.id).toList(), ['poster-nadia']);
    expect(searchMutual.first.isMutualMatch, isTrue);
    expect(searchMutual.first.needMatched, isTrue);
  });

  testWidgets('BarterProposePage: kunci field terpisah & nonaktif bila tidak ada mitra cocok',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AppConfig.customUseMockData = false;
    addTearDown(() => AppConfig.customUseMockData = null);

    const candidates = [
      ServiceListing(
        id: 'poster-nadia',
        title: 'Desain Poster UMKM Pro',
        description: 'Poster promosi UMKM cepat',
        offerType: OfferType.paidAndBarter,
        providerName: 'Nadia Pratiwi',
        skillName: 'Desain UI/UX & Grafis Poster',
        category: 'Desain',
        barterWant: 'Jasa Editing Video Reels',
      ),
    ];

    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies.offline(),
        child: const MaterialApp(
          home: BarterProposePage(initialCandidates: candidates),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Mengisi tautan portofolio tidak boleh mengubah estimasi durasi
    const figmaUrl =
        'https://www.figma.com/design/7BVP6VW8NteNC0cjQulQt3/SakuSkill?node-id=321-996&t=h8K7lgMcfvUmjcTU-0';
    final portfolioFinder = find.byKey(const Key('barter-portfolio-input'));
    await tester.ensureVisible(portfolioFinder);
    await tester.enterText(portfolioFinder, figmaUrl);
    await tester.pumpAndSettle();

    final daysField = tester.widget<SakuTextField>(
      find.byKey(const Key('barter-days-input')),
    );
    final portfolioField = tester.widget<SakuTextField>(portfolioFinder);
    expect(daysField.controller?.text, '4');
    expect(portfolioField.controller?.text, figmaUrl);

    // Cari keahlian yang tidak ditawarkan kandidat -> empty card & submit nonaktif
    await tester.ensureVisible(find.byKey(const Key('barter-match-search')));
    await tester.enterText(
      find.byKey(const Key('barter-match-search')),
      'Install Linux Server',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('barter-match-empty')), findsOneWidget);
    expect(find.byKey(const Key('barter-target-card')), findsNothing);
    expect(find.text('Pilih Mitra yang Sesuai Dahulu'), findsOneWidget);
  });

  testWidgets('WalletPage: kartu metode sama tinggi & 4 kanal E-Wallet sejajar mulus tanpa ChoiceChip',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies.offline(),
        child: const MaterialApp(home: WalletPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceChip), findsNothing);
    final bankBox = tester.getRect(find.text('Transfer Bank').first);
    final ewalletBox = tester.getRect(find.text('E-Wallet').first);
    expect((bankBox.top - ewalletBox.top).abs(), lessThan(2.0));

    await tester.tap(find.text('E-Wallet'));
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceChip), findsNothing);
    final gopayY = tester.getTopLeft(find.text('GoPay')).dy;
    final shopeeY = tester.getTopLeft(find.text('ShopeePay')).dy;
    expect((gopayY - shopeeY).abs(), lessThan(2.0));

    await tester.tap(find.text('OVO'));
    await tester.pumpAndSettle();
    expect(find.text('Nomor HP E-Wallet Tujuan'), findsOneWidget);
  });

  testWidgets('SakuTextField: didUpdateWidget memperbarui controller ketika controller diganti',
      (tester) async {
    final ctrlA = TextEditingController(text: '4');
    final ctrlB = TextEditingController(text: 'https://example.com');
    addTearDown(ctrlA.dispose);
    addTearDown(ctrlB.dispose);

    var useB = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                SakuTextField(
                  controller: useB ? ctrlB : ctrlA,
                  hint: 'Input uji',
                ),
                TextButton(
                  onPressed: () => setState(() => useB = true),
                  child: const Text('Ganti'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('4'), findsOneWidget);
    await tester.tap(find.text('Ganti'));
    await tester.pumpAndSettle();

    expect(find.text('https://example.com'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'https://baru.id');
    await tester.pumpAndSettle();

    expect(ctrlA.text, '4');
    expect(ctrlB.text, 'https://baru.id');
  });
}

class _RecordingBarterDataSource extends BarterRemoteDataSource {
  final List<String> cancelledIds = [];
  final List<String> rejectedIds = [];

  @override
  Future<BarterAgreementModel> getBarterDetail(String barterId) async {
    throw const BarterException('offline test');
  }

  @override
  Future<BarterAgreementModel> cancelBarter(
    String barterId, {
    String? reason,
  }) async {
    cancelledIds.add(barterId);
    return BarterAgreementModel(
      id: barterId,
      listingId: 'lst-1',
      pengajuId: 'aj-id',
      penerimaId: 'np-id',
      deskripsiJasaPengaju: 'Edit Design Canva',
      deskripsiJasaPenerima: 'Editing Reels Tiktok',
      tenggatPekerjaan: DateTime(2026, 12, 1),
      setujuPengaju: true,
      setujuPenerima: false,
      konfirmasiSelesaiPengaju: false,
      konfirmasiSelesaiPenerima: false,
      status: 'Dibatalkan',
      statusKode: 'cancelled',
      namaPengaju: 'Ahmad Jaenudin',
      namaPenerima: 'Nadia Pratiwi',
    );
  }

  @override
  Future<BarterAgreementModel> rejectBarter(
    String barterId, {
    String? reason,
  }) async {
    rejectedIds.add(barterId);
    return BarterAgreementModel(
      id: barterId,
      listingId: 'lst-1',
      pengajuId: 'aj-id',
      penerimaId: 'np-id',
      deskripsiJasaPengaju: 'Edit Design Canva',
      deskripsiJasaPenerima: 'Editing Reels Tiktok',
      tenggatPekerjaan: DateTime(2026, 12, 1),
      setujuPengaju: true,
      setujuPenerima: false,
      konfirmasiSelesaiPengaju: false,
      konfirmasiSelesaiPenerima: false,
      status: 'Ditolak',
      statusKode: 'rejected',
      namaPengaju: 'Ahmad Jaenudin',
      namaPenerima: 'Nadia Pratiwi',
    );
  }
}
