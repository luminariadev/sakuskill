import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/campus_constants.dart';
import '../../../../core/security/rbac_matrix.dart';
import '../../../../core/security/url_sanitizer.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/service_item.dart';
import '../../../escrow/domain/entities/escrow_order.dart';
import '../../../barter/domain/entities/barter_contract.dart';
import '../../../admin/domain/entities/dispute_ticket.dart';

class AppStateProvider extends ChangeNotifier {
  // Pre-seeded verified campus users
  final List<UserEntity> _users = [
    const UserEntity(
      id: 'user-1',
      name: 'Ahmad Fauzi',
      nim: '1227050012',
      major: 'Teknik Informatika',
      faculty: 'Sains dan Teknologi',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
      role: UserRole.provider,
      verifiedStudent: true,
      walletBalance: 275000,
      rating: 4.9,
      reviewCount: 18,
      phone: '081223456789',
      locationName: 'Jl. Manisi (Samping Kampus 1)',
      coordinates: LatLng(-6.9360, 107.7210),
      skills: ['Install Linux Dual-Boot', 'Pembersihan Kipas Laptop', 'Repasta Thermal MX-4'],
    ),
    const UserEntity(
      id: 'user-2',
      name: 'Siti Nurhaliza',
      nim: '1224020089',
      major: 'Komunikasi Penyiaran Islam',
      faculty: 'Dakwah dan Komunikasi',
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=200&q=80',
      role: UserRole.provider,
      verifiedStudent: true,
      walletBalance: 340000,
      rating: 4.9,
      reviewCount: 24,
      phone: '082198765432',
      locationName: 'Gg. Kujang, Cipadung',
      coordinates: LatLng(-6.9302, 107.7198),
      skills: ['Desain Spanduk Seminar', 'Template Feed Instagram', 'Logo Ormawa'],
    ),
    const UserEntity(
      id: 'user-3',
      name: 'Rizky Ramadhan',
      nim: '1214050064',
      major: 'Ilmu Komunikasi Jurnalistik',
      faculty: 'Dakwah dan Komunikasi',
      avatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=200&q=80',
      role: UserRole.provider,
      verifiedStudent: true,
      walletBalance: 490000,
      rating: 5.0,
      reviewCount: 31,
      phone: '085712344321',
      locationName: 'Bundaran Cibiru',
      coordinates: LatLng(-6.9385, 107.7150),
      skills: ['Foto Wisuda Anwar Musaddad', 'Dokumentasi Himpunan', 'Video Sinematik'],
    ),
    const UserEntity(
      id: 'user-4',
      name: 'Farhan Pratama',
      nim: '1238010045',
      major: 'Manajemen',
      faculty: 'Ekonomi dan Bisnis Islam',
      avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
      role: UserRole.client,
      verifiedStudent: true,
      walletBalance: 250000,
      rating: 4.8,
      reviewCount: 7,
      phone: '087855667788',
      locationName: 'Komp. Bumi Harapan Cibiru',
      coordinates: LatLng(-6.9240, 107.7120),
      skills: ['Penyusunan Anggaran Acara', 'Public Speaking & MC'],
    ),
    const UserEntity(
      id: 'user-5',
      name: 'Dr. H. Mulyana',
      nim: 'NIP. 197805122005011003',
      major: 'Bagian Kemahasiswaan & Alumni',
      faculty: 'Gedung Rektorat Lt. 2 Kampus 1 UIN',
      avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=200&q=80',
      role: UserRole.campusAdmin,
      verifiedStudent: true,
      walletBalance: 0,
      rating: 5.0,
      reviewCount: 0,
      phone: '0227800525',
      locationName: 'Rektorat Kampus 1 UIN Cibiru',
      coordinates: LatLng(-6.9317, 107.7176),
      skills: ['Audit Integritas Akademik', 'Mediasi Sengketa Kampus'],
    ),
  ];

  late String _currentUserId;
  bool _isAuthenticated = false;
  final List<ServiceItem> _services = [];
  final List<EscrowOrder> _orders = [];
  final List<BarterContract> _barterContracts = [];
  final List<DisputeTicket> _disputes = [];
  final Set<String> _favoriteServiceIds = {'srv-1', 'srv-3'};

  // Filter state
  String _searchQuery = '';
  ServiceCategory? _selectedCategory;
  double _maxDistanceKm = 3.0;
  bool _barterOnly = false;

  AppStateProvider() {
    _currentUserId = 'user-4'; // Farhan (Client) as default demo user
    _isAuthenticated = false; // Start at Auth/Login flow
    _initSeedData();
  }

  void _initSeedData() {
    _services.addAll([
      ServiceItem(
        id: 'srv-1',
        providerId: 'user-1',
        title: 'Pembersihan Kipas, Heatsink & Ganti Thermal Paste Laptop',
        description: 'Servis pembersihan debu heatsink dan penggantian pasta termal Arctic MX-4 untuk laptop mahasiswa yang cepat panas. Transparan bisa ditunggu di Gazebo Saintek.',
        category: ServiceCategory.itSupport,
        price: 45000,
        acceptsBarter: true,
        barterWishlist: 'Bantuan desain banner acara himpunan atau latihan percakapan bahasa Inggris',
        locationName: 'Jl. Manisi (Samping Kampus 1)',
        coordinates: const LatLng(-6.9360, 107.7210),
        distanceFromCampusKm: 0.6,
        estimatedDeliveryHours: 3,
        imageUrl: 'https://images.unsplash.com/photo-1588508065123-287b28e013da?auto=format&fit=crop&w=800&q=80',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ServiceItem(
        id: 'srv-2',
        providerId: 'user-2',
        title: 'Desain Banner Spanduk & Backdrop Panggung Seminar Ormawa',
        description: 'Desain visual siap cetak resolusi tinggi (CMYK 300dpi format PDF & TIFF). Khusus acara seminar atau pelantikan himpunan dengan 2x revisi minor.',
        category: ServiceCategory.creativeDesign,
        price: 50000,
        acceptsBarter: true,
        barterWishlist: 'Instalasi dual boot Ubuntu Linux atau bantuan setup web server lokal',
        locationName: 'Gg. Kujang, Cipadung',
        coordinates: const LatLng(-6.9302, 107.7198),
        distanceFromCampusKm: 0.3,
        estimatedDeliveryHours: 24,
        imageUrl: 'https://images.unsplash.com/photo-1626785774573-4b799315345d?auto=format&fit=crop&w=800&q=80',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ServiceItem(
        id: 'srv-3',
        providerId: 'user-3',
        title: 'Foto Wisuda & Yudisium Outdoor Spot Gedung Anwar Musaddad',
        description: 'Dokumentasi kelulusan personal dan bersama keluarga. Kamera Sony A7 III + Lensa 85mm. Output: 15 foto edit warna cinematic Google Drive + file mentah.',
        category: ServiceCategory.photography,
        price: 90000,
        acceptsBarter: false,
        locationName: 'Bundaran Cibiru',
        coordinates: const LatLng(-6.9385, 107.7150),
        distanceFromCampusKm: 0.8,
        estimatedDeliveryHours: 48,
        imageUrl: 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=800&q=80',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ServiceItem(
        id: 'srv-4',
        providerId: 'user-1',
        title: 'Setup & Panduan Linux Dual-Boot untuk Praktikum Saintek',
        description: 'Bantuan instalasi Linux (Ubuntu 24.04 / Debian) berdampingan dengan Windows tanpa menghapus partisi. Termasuk instalasi GCC, Python, Git, dan VS Code.',
        category: ServiceCategory.itSupport,
        price: 35000,
        acceptsBarter: true,
        barterWishlist: 'Pinjam lensa kamera 1 hari atau bimbingan persiapan TOEFL',
        locationName: 'Kampus 1 UIN SGD Cibiru',
        coordinates: const LatLng(-6.9317, 107.7176),
        distanceFromCampusKm: 0.0,
        estimatedDeliveryHours: 2,
        imageUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?auto=format&fit=crop&w=800&q=80',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ServiceItem(
        id: 'srv-5',
        providerId: 'user-2',
        title: 'Desain Template Feed Instagram & Carousel Infografis UKM',
        description: 'Paket 3 slide visual informatif untuk publikasi agenda UKM kampus. Didesain rapi, kontras jelas, dan konsisten dengan identitas lembaga. Format PNG transparan.',
        category: ServiceCategory.creativeDesign,
        price: 40000,
        acceptsBarter: true,
        barterWishlist: 'Konsultasi pengolahan rumus dasar Excel atau SPSS',
        locationName: 'Gg. Kujang, Cipadung',
        coordinates: const LatLng(-6.9302, 107.7198),
        distanceFromCampusKm: 0.3,
        estimatedDeliveryHours: 12,
        imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=800&q=80',
        createdAt: DateTime.now().subtract(const Duration(hours: 18)),
      ),
      ServiceItem(
        id: 'srv-6',
        providerId: 'user-1',
        title: 'Mentoring 1-on-1 Pemahaman Logika Algoritma & Dasar Python',
        description: 'Sesi bimbingan 90 menit santai membahas alur logika algoritma, perulangan, dan fungsi pemrograman dasar. Bukan joki tugas, melainkan penguatan logika berpikir.',
        category: ServiceCategory.tutoring,
        price: 35000,
        acceptsBarter: true,
        barterWishlist: 'Latihan percakapan bahasa Arab percakapan amiyah atau fusha',
        locationName: 'Perpustakaan Utama Kampus 1 UIN',
        coordinates: const LatLng(-6.9317, 107.7176),
        distanceFromCampusKm: 0.0,
        estimatedDeliveryHours: 2,
        imageUrl: 'https://images.unsplash.com/photo-1515378791036-0648a3ef77b2?auto=format&fit=crop&w=800&q=80',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      ServiceItem(
        id: 'srv-7',
        providerId: 'user-3',
        title: 'Video Sinematik Dokumentasi Kegiatan Organisasi & Profil UKM',
        description: 'Produksi video vertikal pendek (Reels/TikTok) durasi 60 detik + grading warna sinematik. Menggunakan gimbal stabilizer dan mic wireless Saramonic.',
        category: ServiceCategory.photography,
        price: 75000,
        acceptsBarter: true,
        barterWishlist: 'Bimbingan instalasi CMS WordPress atau jasa artikel SEO',
        locationName: 'Bundaran Cibiru Kampus UIN',
        coordinates: const LatLng(-6.9385, 107.7150),
        distanceFromCampusKm: 0.8,
        estimatedDeliveryHours: 24,
        imageUrl: 'https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d?auto=format&fit=crop&w=800&q=80',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      ServiceItem(
        id: 'srv-8',
        providerId: 'user-2',
        title: 'Desain CV ATS Friendly & Portofolio Mahasiswa Siap Magang MSIB',
        description: 'Format standar internasional lolos scanner ATS. Disesuaikan dengan bidang studi dan industri incaran. Format deliverable Word DOCX + PDF.',
        category: ServiceCategory.creativeDesign,
        price: 35000,
        acceptsBarter: true,
        barterWishlist: 'Bimbingan TOEFL ITP atau les dasar percakapan Inggris',
        locationName: 'Gg. Kujang, Cipadung',
        coordinates: const LatLng(-6.9302, 107.7198),
        distanceFromCampusKm: 0.3,
        estimatedDeliveryHours: 12,
        imageUrl: 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?auto=format&fit=crop&w=800&q=80',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ]);

    _orders.addAll([
      EscrowOrder(
        id: 'ord-101',
        serviceId: 'srv-2',
        serviceTitle: 'Desain Banner Spanduk & Backdrop Panggung Seminar Ormawa',
        category: ServiceCategory.creativeDesign,
        buyerId: 'user-4',
        sellerId: 'user-2',
        amount: 50000,
        status: EscrowStatus.workSubmitted,
        escrowLockedAt: DateTime.now().subtract(const Duration(hours: 14)),
        deliverableProofUrl: 'https://drive.google.com/drive/folders/demo-banner-seminar-uin',
        deliverableNotes: 'File banner resolusi tinggi siap cetak format PDF & JPG sudah diunggah. Mohon dicek ya Kang Farhan!',
        workSubmittedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      EscrowOrder(
        id: 'ord-100',
        serviceId: 'srv-1',
        serviceTitle: 'Pembersihan Kipas, Heatsink & Ganti Thermal Paste Laptop',
        category: ServiceCategory.itSupport,
        buyerId: 'user-4',
        sellerId: 'user-1',
        amount: 45000,
        status: EscrowStatus.completed,
        escrowLockedAt: DateTime.now().subtract(const Duration(days: 2)),
        deliverableProofUrl: 'https://drive.google.com/laptop-repasta-proof.jpg',
        deliverableNotes: 'Laptop Asus sudah dibersihkan kipasnya dan repasta Arctic MX-4. Suhu idle stabil 46C.',
        workSubmittedAt: DateTime.now().subtract(const Duration(days: 2, hours: -3)),
        completedAt: DateTime.now().subtract(const Duration(days: 2, hours: -4)),
      ),
      EscrowOrder(
        id: 'ord-102',
        serviceId: 'srv-7',
        serviceTitle: 'Video Sinematik Dokumentasi Kegiatan Organisasi & Profil UKM',
        category: ServiceCategory.photography,
        buyerId: 'user-1',
        sellerId: 'user-3',
        amount: 75000,
        status: EscrowStatus.escrowLocked,
        escrowLockedAt: DateTime.now().subtract(const Duration(hours: 5)),
        deliverableNotes: 'Dokumentasi acara inaugurasi mahasiswa baru angkatan 2024.',
      ),
    ]);

    _barterContracts.addAll([
      BarterContract(
        id: 'barter-201',
        initiatorId: 'user-1',
        initiatorServiceTitle: 'Setup & Panduan Linux Dual-Boot Ubuntu',
        initiatorDeliverableProof: 'https://drive.google.com/dualboot-setup-log.txt',
        initiatorApproved: true,
        partnerId: 'user-2',
        partnerServiceTitle: 'Desain Logo & Mockup Kaos Angkatan Teknik Informatika',
        partnerDeliverableProof: 'https://drive.google.com/logo-angkatan-ti.svg',
        partnerApproved: false,
        termsAndAgreement: 'Pertukaran bilateral: Ahmad bantu instalasi dual-boot Linux untuk Siti, dan Siti bantu pembuatan logo kaos angkatan untuk Ahmad. Selesai jika kedua belah pihak saling mengunggah dan memverifikasi.',
        status: BarterStatus.bothSubmitted,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      BarterContract(
        id: 'barter-202',
        initiatorId: 'user-4',
        initiatorServiceTitle: 'Penyusunan Format RAB & Presentasi Sponsorship Acara',
        partnerId: 'user-1',
        partnerServiceTitle: 'Pembersihan Kipas, Heatsink & Ganti Thermal Paste Laptop',
        initiatorApproved: true,
        partnerApproved: false,
        termsAndAgreement: 'Farhan bantu perapihan RAB kegiatan BEM, dan Ahmad bantu bersihkan kipas laptop Farhan.',
        status: BarterStatus.proposed,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ]);

    _disputes.addAll([
      DisputeTicket(
        id: 'disp-401',
        transactionId: 'ord-101',
        orderType: 'ESCROW',
        raisedById: 'user-4',
        reason: 'File poster yang diserahkan memiliki tanggal kegiatan yang keliru dan penyedia belum merespons pesan revisi.',
        evidenceNotes: 'Tercantum tanggal 23 Oktober padahal brief tertulis 26 Oktober. Chat WhatsApp tidak dibalas selama 24 jam.',
        status: DisputeStatus.open,
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
      ),
      DisputeTicket(
        id: 'disp-400',
        transactionId: 'ord-95',
        orderType: 'ESCROW',
        raisedById: 'user-2',
        reason: 'Pemesan menolak konfirmasi pencairan dana meskipun revisi ketiga telah diserahkan sesuai kesepakatan.',
        evidenceNotes: 'Pekerjaan logo ormawa selesai dan sesuai format vektor SVG. Mediasi komite etik menyelesaikan sengketa dengan pencairan penuh ke penjual.',
        status: DisputeStatus.resolved,
        resolutionAction: ResolutionAction.releaseToSeller,
        resolutionNotes: 'Komite Etik Kampus memverifikasi bahwa file deliverable telah memenuhi seluruh kriteria brief awal.',
        resolvedAt: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ]);
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  List<UserEntity> get users => List.unmodifiable(_users);
  UserEntity get currentUser => _users.firstWhere((u) => u.id == _currentUserId);
  List<EscrowOrder> get orders => List.unmodifiable(_orders);
  List<BarterContract> get barterContracts => List.unmodifiable(_barterContracts);
  List<DisputeTicket> get disputes => List.unmodifiable(_disputes);

  String get searchQuery => _searchQuery;
  ServiceCategory? get selectedCategory => _selectedCategory;
  double get maxDistanceKm => _maxDistanceKm;
  bool get barterOnly => _barterOnly;

  List<ServiceItem> get allServices => List.unmodifiable(_services);
  List<ServiceItem> get currentUserServices => _services.where((s) => s.providerId == _currentUserId).toList();
  List<ServiceItem> get popularServices => _services.where((s) => s.category == ServiceCategory.itSupport || s.category == ServiceCategory.creativeDesign).toList();
  List<ServiceItem> get barterServices => _services.where((s) => s.acceptsBarter).toList();
  int get activeOrdersCount => _orders.where((o) => (o.buyerId == _currentUserId || o.sellerId == _currentUserId) && o.status != EscrowStatus.completed && o.status != EscrowStatus.refunded).length;

  bool isFavorite(String serviceId) => _favoriteServiceIds.contains(serviceId);

  void toggleFavorite(String serviceId) {
    if (_favoriteServiceIds.contains(serviceId)) {
      _favoriteServiceIds.remove(serviceId);
    } else {
      _favoriteServiceIds.add(serviceId);
    }
    notifyListeners();
  }

  List<ServiceItem> get filteredServices {
    return _services.where((item) {
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      if (_barterOnly && !item.acceptsBarter) {
        return false;
      }
      if (item.distanceFromCampusKm > _maxDistanceKm) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(q);
        final matchDesc = item.description.toLowerCase().contains(q);
        final matchLoc = item.locationName.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchLoc) return false;
      }
      return true;
    }).toList();
  }

  // User authentication & switcher
  void login(String userId) {
    if (_users.any((u) => u.id == userId)) {
      _currentUserId = userId;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  void registerUser({
    required String name,
    required String nim,
    required String major,
    required String faculty,
    required UserRole role,
    required List<String> skills,
    required String phone,
  }) {
    final newId = 'user-${_users.length + 1}';
    final newUser = UserEntity(
      id: newId,
      name: name.trim(),
      nim: nim.trim(),
      major: major.trim(),
      faculty: faculty.trim(),
      avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
      role: role,
      verifiedStudent: true,
      walletBalance: 150000, // Saldo awal uji coba
      rating: 5.0,
      reviewCount: 0,
      phone: phone.trim(),
      locationName: 'Kampus 1 UIN SGD Cibiru',
      coordinates: const LatLng(-6.9317, 107.7176),
      skills: skills,
    );
    _users.add(newUser);
    _currentUserId = newId;
    _isAuthenticated = true;
    notifyListeners();
  }

  void switchUser(String userId) {
    if (_users.any((u) => u.id == userId)) {
      _currentUserId = userId;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  bool topUpBalance(int amount) {
    if (amount <= 0 || amount > 5000000) return false;
    final idx = _users.indexWhere((u) => u.id == _currentUserId);
    if (idx != -1) {
      final current = _users[idx];
      _users[idx] = current.copyWith(walletBalance: current.walletBalance + amount);
      notifyListeners();
      return true;
    }
    return false;
  }

  // Filter modifiers
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(ServiceCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setMaxDistanceKm(double km) {
    _maxDistanceKm = km;
    notifyListeners();
  }

  void toggleBarterOnly() {
    _barterOnly = !_barterOnly;
    notifyListeners();
  }

  // RBAC Gated: Create Service
  String? createService({
    required String title,
    required String description,
    required ServiceCategory category,
    required int price,
    required bool acceptsBarter,
    String? barterWishlist,
    required String locationName,
    required LatLng coordinates,
    required int estimatedDeliveryHours,
    required String imageUrl,
  }) {
    if (!RbacMatrix.hasPermission(currentUser.role, AppPermission.serviceCreate)) {
      return 'Akses Ditolak (RBAC): Hanya Mahasiswa dengan peran Penyedia (PROVIDER) yang berhak mempublikasikan penawaran jasa.';
    }

    if (price < 5000) {
      return 'Batas Tarif: Tarif minimal jasa mahasiswa adalah Rp 5.000.';
    }
    if (price > 5000000) {
      return 'Batas Tarif: Maksimal tarif mikro-servis mahasiswa adalah Rp 5.000.000.';
    }

    if (SecuritySanitizer.containsForbiddenKeywords(title) ||
        SecuritySanitizer.containsForbiddenKeywords(description)) {
      return 'Pelanggaran Etika: Dilarang menawarkan jasa perjokian tugas akademik/skripsi.';
    }

    final double distance = FormatterUtils.calculateDistanceKm(CampusConstants.campusLocation, coordinates);

    final newService = ServiceItem(
      id: 'srv-${DateTime.now().millisecondsSinceEpoch}',
      providerId: currentUser.id,
      title: title.trim(),
      description: description.trim(),
      category: category,
      price: price,
      acceptsBarter: acceptsBarter,
      barterWishlist: acceptsBarter ? barterWishlist?.trim() : null,
      locationName: locationName,
      coordinates: coordinates,
      distanceFromCampusKm: distance,
      estimatedDeliveryHours: estimatedDeliveryHours,
      imageUrl: imageUrl.trim().isNotEmpty
          ? imageUrl.trim()
          : 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=800&q=80',
      createdAt: DateTime.now(),
    );

    _services.insert(0, newService);
    notifyListeners();
    return null;
  }

  // RBAC Gated: Order Service with Escrow Lock
  String? createEscrowOrder({
    required ServiceItem service,
    String? notes,
  }) {
    if (!RbacMatrix.hasPermission(currentUser.role, AppPermission.serviceOrder)) {
      return 'Akses Ditolak (RBAC): Akun Anda tidak memiliki izin untuk memesan jasa.';
    }

    if (service.providerId == currentUser.id) {
      return 'Integritas Transaksi: Anda tidak dapat memesan layanan yang Anda sediakan sendiri.';
    }

    if (currentUser.walletBalance < service.price) {
      return 'Saldo tidak mencukupi (${FormatterUtils.formatIDR(currentUser.walletBalance)} vs ${FormatterUtils.formatIDR(service.price)}). Silakan klik +Top Up terlebih dahulu.';
    }

    // Deduct buyer's wallet balance into Escrow lock
    final buyerIdx = _users.indexWhere((u) => u.id == currentUser.id);
    if (buyerIdx != -1) {
      final buyer = _users[buyerIdx];
      _users[buyerIdx] = buyer.copyWith(walletBalance: buyer.walletBalance - service.price);
    }

    final newOrder = EscrowOrder(
      id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
      serviceId: service.id,
      serviceTitle: service.title,
      category: service.category,
      buyerId: currentUser.id,
      sellerId: service.providerId,
      amount: service.price,
      status: EscrowStatus.escrowLocked,
      escrowLockedAt: DateTime.now(),
      deliverableNotes: notes?.trim(),
    );

    _orders.insert(0, newOrder);
    notifyListeners();
    return null;
  }

  // RBAC Gated: Submit Work Deliverable
  String? submitDeliverable({
    required String orderId,
    required String proofUrl,
    required String notes,
  }) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return 'Pesanan tidak ditemukan.';

    final order = _orders[idx];
    if (order.sellerId != currentUser.id) {
      return 'Akses Ditolak (RBAC): Hanya penyedia jasa resmi untuk pesanan ini yang dapat mengunggah bukti pengerjaan.';
    }

    if (!SecuritySanitizer.isValidSecureUrl(proofUrl)) {
      return 'Validasi Keamanan Gagal: Tautan bukti deliverable harus berprotokol HTTPS/HTTP (misal: Google Drive, GitHub). Skema skrip berbahaya diblokir.';
    }

    _orders[idx] = order.copyWith(
      status: EscrowStatus.workSubmitted,
      deliverableProofUrl: proofUrl.trim(),
      deliverableNotes: notes.trim(),
      workSubmittedAt: DateTime.now(),
    );

    notifyListeners();
    return null;
  }

  // RBAC Gated: Release Escrow Funds to Seller
  String? completeEscrowOrder(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return 'Pesanan tidak ditemukan.';

    final order = _orders[idx];
    if (order.buyerId != currentUser.id) {
      return 'Akses Ditolak (RBAC): Hanya pembeli pemesan yang berhak mencairkan dana escrow.';
    }

    if (order.status != EscrowStatus.workSubmitted) {
      return 'State Machine Error: Dana hanya dapat dicairkan setelah penyedia menyerahkan bukti pengerjaan.';
    }

    // Transfer escrow funds to seller's wallet
    final sellerIdx = _users.indexWhere((u) => u.id == order.sellerId);
    if (sellerIdx != -1) {
      final seller = _users[sellerIdx];
      _users[sellerIdx] = seller.copyWith(walletBalance: seller.walletBalance + order.amount);
    }

    _orders[idx] = order.copyWith(
      status: EscrowStatus.completed,
      completedAt: DateTime.now(),
    );

    notifyListeners();
    return null;
  }

  // Barter actions
  String? createBarterProposal({
    required String partnerId,
    required String initiatorServiceTitle,
    required String partnerServiceTitle,
    required String terms,
  }) {
    if (currentUser.id == partnerId) {
      return 'Anda tidak dapat mengajukan barter ke diri sendiri.';
    }

    final newContract = BarterContract(
      id: 'barter-${DateTime.now().millisecondsSinceEpoch}',
      initiatorId: currentUser.id,
      initiatorServiceTitle: initiatorServiceTitle.trim(),
      initiatorApproved: false,
      partnerId: partnerId,
      partnerServiceTitle: partnerServiceTitle.trim(),
      partnerApproved: false,
      termsAndAgreement: terms.trim(),
      status: BarterStatus.proposed,
      createdAt: DateTime.now(),
    );

    _barterContracts.insert(0, newContract);
    notifyListeners();
    return null;
  }

  String? submitBarterDeliverable({
    required String contractId,
    required bool isInitiator,
    required String proofUrl,
  }) {
    final idx = _barterContracts.indexWhere((c) => c.id == contractId);
    if (idx == -1) return 'Kontrak tidak ditemukan.';

    final contract = _barterContracts[idx];
    if (isInitiator && contract.initiatorId != currentUser.id) {
      return 'Akses Ditolak: Anda bukan inisiator kontrak ini.';
    }
    if (!isInitiator && contract.partnerId != currentUser.id) {
      return 'Akses Ditolak: Anda bukan mitra kontrak ini.';
    }

    if (!SecuritySanitizer.isValidSecureUrl(proofUrl)) {
      return 'Validasi Keamanan Gagal: Tautan bukti deliverable harus berprotokol HTTPS/HTTP.';
    }

    final updated = contract.copyWith(
      initiatorDeliverableProof: isInitiator ? proofUrl.trim() : contract.initiatorDeliverableProof,
      partnerDeliverableProof: !isInitiator ? proofUrl.trim() : contract.partnerDeliverableProof,
    );

    final bool bothSubmitted = (isInitiator ? true : updated.initiatorDeliverableProof != null) &&
        (!isInitiator ? true : updated.partnerDeliverableProof != null);

    _barterContracts[idx] = updated.copyWith(
      status: bothSubmitted ? BarterStatus.bothSubmitted : BarterStatus.partiallySubmitted,
    );

    notifyListeners();
    return null;
  }

  String? approveBarterContract({
    required String contractId,
    required bool isInitiator,
  }) {
    final idx = _barterContracts.indexWhere((c) => c.id == contractId);
    if (idx == -1) return 'Kontrak tidak ditemukan.';

    final contract = _barterContracts[idx];
    final bool initiatorApproved = isInitiator ? true : contract.initiatorApproved;
    final bool partnerApproved = !isInitiator ? true : contract.partnerApproved;
    final bool fullyApproved = initiatorApproved && partnerApproved;

    _barterContracts[idx] = contract.copyWith(
      initiatorApproved: initiatorApproved,
      partnerApproved: partnerApproved,
      status: fullyApproved ? BarterStatus.completed : contract.status,
      completedAt: fullyApproved ? DateTime.now() : null,
    );

    notifyListeners();
    return null;
  }

  // Open Dispute
  String? openDispute({
    required String transactionId,
    required String orderType,
    required String reason,
    required String evidenceNotes,
  }) {
    if (reason.trim().isEmpty) {
      return 'Alasan komplain/sengketa wajib diisi.';
    }

    if (orderType == 'ESCROW') {
      final idx = _orders.indexWhere((o) => o.id == transactionId);
      if (idx == -1) return 'Pesanan tidak ditemukan.';
      final order = _orders[idx];
      if (order.buyerId != currentUser.id && order.sellerId != currentUser.id) {
        return 'Akses Ditolak (BOLA / IDOR): Anda bukan pihak yang terlibat dalam transaksi ini.';
      }
      if (order.status == EscrowStatus.completed || order.status == EscrowStatus.refunded) {
        return 'Transaksi ini sudah selesai atau di-refund.';
      }
      _orders[idx] = order.copyWith(status: EscrowStatus.dispute);
    }

    final newDispute = DisputeTicket(
      id: 'disp-${DateTime.now().millisecondsSinceEpoch}',
      transactionId: transactionId,
      orderType: orderType,
      raisedById: currentUser.id,
      reason: reason.trim(),
      evidenceNotes: evidenceNotes.trim(),
      status: DisputeStatus.open,
      createdAt: DateTime.now(),
    );

    _disputes.insert(0, newDispute);
    notifyListeners();
    return null;
  }

  // STRICT RBAC: Only Campus Admin can resolve disputes!
  String? resolveDispute({
    required String disputeId,
    required ResolutionAction action,
    required String notes,
  }) {
    if (currentUser.role != UserRole.campusAdmin) {
      return 'Akses Ditolak (Privilege Violation): Hanya pejabat Komite Etik Kampus (CAMPUS_ADMIN) yang berwenang mengeksekusi dana sengketa.';
    }

    final idx = _disputes.indexWhere((d) => d.id == disputeId);
    if (idx == -1) return 'Tiket sengketa tidak ditemukan.';

    final dispute = _disputes[idx];
    if (dispute.status != DisputeStatus.open) {
      return 'State Machine Violation: Sengketa perkara #${dispute.id} sudah pernah diputus dan ditutup.';
    }

    if (dispute.orderType == 'ESCROW') {
      final orderIdx = _orders.indexWhere((o) => o.id == dispute.transactionId);
      if (orderIdx != -1) {
        final order = _orders[orderIdx];
        if (action == ResolutionAction.refundToBuyer) {
          final buyerIdx = _users.indexWhere((u) => u.id == order.buyerId);
          if (buyerIdx != -1) {
            _users[buyerIdx] = _users[buyerIdx].copyWith(walletBalance: _users[buyerIdx].walletBalance + order.amount);
          }
          _orders[orderIdx] = order.copyWith(status: EscrowStatus.refunded);
        } else if (action == ResolutionAction.releaseToSeller) {
          final sellerIdx = _users.indexWhere((u) => u.id == order.sellerId);
          if (sellerIdx != -1) {
            _users[sellerIdx] = _users[sellerIdx].copyWith(walletBalance: _users[sellerIdx].walletBalance + order.amount);
          }
          _orders[orderIdx] = order.copyWith(status: EscrowStatus.completed);
        } else if (action == ResolutionAction.split5050) {
          final half = (order.amount / 2).round();
          final buyerIdx = _users.indexWhere((u) => u.id == order.buyerId);
          if (buyerIdx != -1) {
            _users[buyerIdx] = _users[buyerIdx].copyWith(walletBalance: _users[buyerIdx].walletBalance + half);
          }
          final sellerIdx = _users.indexWhere((u) => u.id == order.sellerId);
          if (sellerIdx != -1) {
            _users[sellerIdx] = _users[sellerIdx].copyWith(walletBalance: _users[sellerIdx].walletBalance + half);
          }
          _orders[orderIdx] = order.copyWith(status: EscrowStatus.completed);
        }
      }
    }

    _disputes[idx] = dispute.copyWith(
      status: DisputeStatus.resolved,
      resolutionAction: action,
      resolutionNotes: notes.trim(),
      resolvedAt: DateTime.now(),
    );

    notifyListeners();
    return null;
  }
}
