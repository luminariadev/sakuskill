import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sakuskill_mobile/core/constants/campus_constants.dart';
import 'package:sakuskill_mobile/core/security/rbac_matrix.dart';
import 'package:sakuskill_mobile/core/security/url_sanitizer.dart';
import 'package:sakuskill_mobile/features/admin/domain/entities/dispute_ticket.dart';
import 'package:sakuskill_mobile/features/ai_estimator/data/datasources/nine_router_ai_service.dart';
import 'package:sakuskill_mobile/features/ai_estimator/domain/usecases/calculate_ai_price.dart';
import 'package:sakuskill_mobile/features/services/presentation/providers/app_state_provider.dart';

void main() {
  group('Security & Anti-Joki Unit Tests (Strix Compliance)', () {
    test('Anti-Joki validator should block academic cheating keywords', () {
      expect(SecuritySanitizer.containsForbiddenKeywords('Joki skripsi bab 1 sampai 5 selesai 3 hari'), isTrue);
      expect(SecuritySanitizer.containsForbiddenKeywords('Jasa pengerjaan kuis kalkulus'), isTrue);
      expect(SecuritySanitizer.containsForbiddenKeywords('Joki tugas mingguan algo'), isTrue);
      expect(SecuritySanitizer.containsForbiddenKeywords('Jasa service keyboard laptop kotor dan ganti pasta'), isFalse);
      expect(SecuritySanitizer.containsForbiddenKeywords('Desain banner spanduk kegiatan himpunan'), isFalse);
    });

    test('URL Sanitizer should strictly enforce HTTP/HTTPS and safe URL formats', () {
      expect(SecuritySanitizer.isValidSecureUrl('ftp://drive.google.com/file'), isFalse);
      expect(SecuritySanitizer.isValidSecureUrl('javascript:alert(1)'), isFalse);
      expect(SecuritySanitizer.isValidSecureUrl('data:text/html;base64,PHNjcmlwdD4='), isFalse);
      expect(SecuritySanitizer.isValidSecureUrl('https://drive.google.com/file/d/123/view'), isTrue);
      expect(SecuritySanitizer.isValidSecureUrl('https://github.com/uinsgd/project'), isTrue);
    });

    test('RBAC matrix enforces strict role-based access control', () {
      expect(RbacMatrix.hasPermission(UserRole.client, AppPermission.adminAccess), isFalse);
      expect(RbacMatrix.hasPermission(UserRole.provider, AppPermission.adminAccess), isFalse);
      expect(RbacMatrix.hasPermission(UserRole.campusAdmin, AppPermission.adminAccess), isTrue);

      expect(RbacMatrix.hasPermission(UserRole.client, AppPermission.serviceCreate), isFalse);
      expect(RbacMatrix.hasPermission(UserRole.provider, AppPermission.serviceCreate), isTrue);
      expect(RbacMatrix.hasPermission(UserRole.client, AppPermission.serviceOrder), isTrue);
    });
  });

  group('Clean Architecture AI Estimator UseCase & 9router Tests', () {
    test('CalculateAIPriceUseCase returns student-friendly price bounds', () {
      final result = CalculateAIPriceUseCase.execute(
        category: ServiceCategory.creativeDesign,
        complexity: ServiceComplexity.simple,
        deliveryHours: 2,
        outputFormat: OutputFormat.digitalFile,
      );

      expect(result.recommendedPrice, greaterThanOrEqualTo(10000));
      expect(result.minPrice, lessThanOrEqualTo(result.recommendedPrice));
      expect(result.maxPrice, greaterThanOrEqualTo(result.recommendedPrice));
      expect(result.academicSafetyNotice, contains('perjokian tugas kuliah'));
      expect(result.calculationBreakdown, isNotEmpty);
    });

    test('NineRouterAIService configuration and fallback robustness', () async {
      expect(NineRouterAIService.modelName, equals('openai/gpt-oss-120b'));
      expect(NineRouterAIService.baseUrl, contains('api.groq.com'));

      final estimate = await NineRouterAIService.estimatePrice(
        category: ServiceCategory.itSupport,
        complexity: ServiceComplexity.medium,
        deliveryHours: 3,
        outputFormat: OutputFormat.onSitePresence,
      );

      expect(estimate.recommendedPrice, greaterThan(0));
      expect(estimate.minPrice, lessThanOrEqualTo(estimate.recommendedPrice));
      expect(estimate.maxPrice, greaterThanOrEqualTo(estimate.recommendedPrice));
      expect(estimate.calculationBreakdown, isNotEmpty);
    });
  });

  group('Authentication Lifecycle & Role Dummy Data Integrity Tests', () {
    test('AppStateProvider initializes with authentication false to start from AuthPage', () {
      final state = AppStateProvider();
      expect(state.isAuthenticated, isFalse);
    });

    test('AppStateProvider login switches user and sets isAuthenticated true', () {
      final state = AppStateProvider();
      state.login('user-1'); // Ahmad Fauzi
      expect(state.isAuthenticated, isTrue);
      expect(state.currentUser.id, equals('user-1'));
      expect(state.currentUser.role, equals(UserRole.provider));

      state.logout();
      expect(state.isAuthenticated, isFalse);
    });

    test('All seeded roles have rich profile data and valid gigs', () {
      final state = AppStateProvider();

      // Check all 5 users exist with verified info
      expect(state.users.length, greaterThanOrEqualTo(5));

      final client = state.users.firstWhere((u) => u.role == UserRole.client);
      expect(client.name, equals('Farhan Pratama'));
      expect(client.walletBalance, greaterThan(0));

      final providers = state.users.where((u) => u.role == UserRole.provider).toList();
      expect(providers.length, greaterThanOrEqualTo(3));

      final admin = state.users.firstWhere((u) => u.role == UserRole.campusAdmin);
      expect(admin.name, equals('Dr. H. Mulyana'));

      // Check gigs and orders
      expect(state.allServices.length, greaterThanOrEqualTo(6));
      expect(state.orders.length, greaterThanOrEqualTo(2));
      expect(state.barterContracts.length, greaterThanOrEqualTo(2));
      expect(state.disputes.length, greaterThanOrEqualTo(2));
    });

    test('Registering new student user succeeds and sets active session', () {
      final state = AppStateProvider();
      state.registerUser(
        name: 'Budi Santoso',
        nim: '1227050099',
        major: 'Teknik Informatika',
        faculty: 'Sains dan Teknologi',
        role: UserRole.provider,
        skills: ['Pemrograman Dart', 'Flutter Mobile'],
        phone: '081299887766',
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.currentUser.name, equals('Budi Santoso'));
      expect(state.currentUser.role, equals(UserRole.provider));
      expect(state.currentUser.walletBalance, equals(150000));
    });
  });

  group('Strix Autonomous Security & Transaction State Machine Tests', () {
    test('BOLA / IDOR Protection: User cannot open dispute on an order they do not belong to', () {
      final state = AppStateProvider();
      // ord-101 is between buyer user-4 and seller user-2.
      // user-3 (Rizky) is an outsider.
      state.login('user-3');
      final err = state.openDispute(
        transactionId: 'ord-101',
        orderType: 'ESCROW',
        reason: 'Unauthorized dispute attempt by third party',
        evidenceNotes: 'Malicious IDOR payload',
      );

      expect(err, contains('BOLA / IDOR'));
    });

    test('Transaction Finality Guard: Cannot open dispute on completed or refunded orders', () {
      final state = AppStateProvider();
      // ord-100 is completed between buyer user-4 and seller user-1.
      state.login('user-4');
      final err = state.openDispute(
        transactionId: 'ord-100',
        orderType: 'ESCROW',
        reason: 'Order was already completed and funds settled',
        evidenceNotes: 'Belated claim attempt',
      );

      expect(err, contains('sudah selesai'));
    });

    test('Double-Spending & Replay Attack Protection: Cannot resolve the same dispute twice', () {
      final state = AppStateProvider();
      // disp-400 is already resolved
      state.login('user-5'); // Campus Admin
      final err = state.resolveDispute(
        disputeId: 'disp-400',
        action: ResolutionAction.refundToBuyer,
        notes: 'Replay exploit execution attempt',
      );

      expect(err, contains('State Machine Violation'));
    });

    test('Privilege Escalation Protection: Regular client or provider cannot resolve disputes', () {
      final state = AppStateProvider();
      state.login('user-1'); // Ahmad (Provider)
      final err = state.resolveDispute(
        disputeId: 'disp-401',
        action: ResolutionAction.releaseToSeller,
        notes: 'Illegitimate self-payout',
      );

      expect(err, contains('Privilege Violation'));
    });

    test('Escrow Settlement Execution: Campus admin can refund buyer or release to seller correctly', () {
      final state = AppStateProvider();
      state.login('user-5'); // Campus admin Dr. Mulyana

      // ord-98 is in disp-401 (amount: 50000, buyer: user-4, seller: user-2)
      final buyerBefore = state.users.firstWhere((u) => u.id == 'user-4').walletBalance;

      final err = state.resolveDispute(
        disputeId: 'disp-401',
        action: ResolutionAction.refundToBuyer,
        notes: 'Komite memutuskan pembatalan dan refund 100% ke pemesan.',
      );

      expect(err, isNull);

      final buyerAfter = state.users.firstWhere((u) => u.id == 'user-4').walletBalance;
      expect(buyerAfter, equals(buyerBefore + 50000));

      final disputeAfter = state.disputes.firstWhere((d) => d.id == 'disp-401');
      expect(disputeAfter.status, equals(DisputeStatus.resolved));
    });

    test('Anti-Tampering: Financial input boundaries for Top-Up and Gig Creation', () {
      final state = AppStateProvider();
      state.login('user-1'); // Provider

      // Reject negative and excessive top-up
      expect(state.topUpBalance(-50000), isFalse);
      expect(state.topUpBalance(0), isFalse);
      expect(state.topUpBalance(10000000), isFalse);
      expect(state.topUpBalance(100000), isTrue);

      // Reject gig creation under Rp 5.000 or over Rp 5.000.000
      final errUnder = state.createService(
        title: 'Bantu ketik 1 paragraf',
        description: 'Mengetik cepat',
        category: ServiceCategory.itSupport,
        price: 1000,
        acceptsBarter: false,
        locationName: 'Gazebo Saintek',
        coordinates: const LatLng(-6.9360, 107.7210),
        estimatedDeliveryHours: 1,
        imageUrl: '',
      );
      expect(errUnder, contains('Batas Tarif'));

      final errOver = state.createService(
        title: 'Beli Server Kampus',
        description: 'Server bekas',
        category: ServiceCategory.itSupport,
        price: 10000000,
        acceptsBarter: false,
        locationName: 'Gazebo Saintek',
        coordinates: const LatLng(-6.9360, 107.7210),
        estimatedDeliveryHours: 1,
        imageUrl: '',
      );
      expect(errOver, contains('Batas Tarif'));
    });

    test('Transaction Integrity: Self-ordering and Insufficient Balance Guards', () {
      final state = AppStateProvider();
      state.login('user-1'); // Ahmad owns srv-1

      final service = state.allServices.firstWhere((s) => s.id == 'srv-1');
      final selfOrderErr = state.createEscrowOrder(service: service);
      expect(selfOrderErr, contains('tidak dapat memesan layanan yang Anda sediakan sendiri'));

      // Barter with oneself is blocked
      final selfBarterErr = state.createBarterProposal(
        partnerId: 'user-1',
        initiatorServiceTitle: 'Jasa A',
        partnerServiceTitle: 'Jasa B',
        terms: 'Barter diri sendiri',
      );
      expect(selfBarterErr, contains('tidak dapat mengajukan barter ke diri sendiri'));
    });
  });
}
