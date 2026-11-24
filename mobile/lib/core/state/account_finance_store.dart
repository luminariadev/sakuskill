import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/data/auth_session.dart';
import '../../features/escrow/data/models/escrow_order_model.dart';
import '../../features/escrow/domain/repositories/escrow_repository.dart';
import '../config/app_config.dart';
import '../demo/demo_data.dart';
import '../utils/formatters.dart';

/// Catatan mutasi dompet simulasi (disusun dari transaksi real & penarikan
/// simulasi di sesi aktif, atau data contoh saat `AppConfig.useMockData`).
class WalletMutation {
  const WalletMutation({
    required this.title,
    required this.amountLabel,
    required this.note,
    this.incoming = false,
  });

  final String title;
  final String amountLabel;
  final String note;
  final bool incoming;
}

/// Sumber kebenaran tunggal untuk saldo, dana ditahan escrow, jumlah transaksi
/// aktif, jumlah layanan aktif, dan riwayat mutasi di Beranda, Dompet,
/// Aktivitas, dan Profil agar selalu sinkron dan dimulai dari Rp 0 untuk akun baru.
class AccountFinanceStore extends ChangeNotifier {
  AccountFinanceStore._({bool? useMockOverride})
      : _useMockOverride = useMockOverride;

  static final AccountFinanceStore instance = AccountFinanceStore._();

  @visibleForTesting
  factory AccountFinanceStore.forTest({bool useMock = false}) =>
      AccountFinanceStore._(useMockOverride: useMock);

  final bool? _useMockOverride;

  String? _activeUserId;
  int _earnedBalance = 0;
  int _withdrawnTotal = 0;
  int _escrowHeld = 0;
  int _activeOrderCount = 0;
  int _myServiceCount = 0;
  bool _syncedOnce = false;
  bool _refreshing = false;

  final List<WalletMutation> _withdrawals = [];
  List<WalletMutation> _orderMutations = const [];

  bool get _useMock => _useMockOverride ?? AppConfig.useMockData;

  /// Saldo pendapatan yang siap ditarik (dalam mode live = hasil pesanan selesai
  /// penyedia dikurangi penarikan simulasi; akun baru mulai Rp 0).
  int get availableBalance {
    final base = (_useMock && !_syncedOnce) ? 250000 : _earnedBalance;
    final net = base - _withdrawnTotal;
    return net > 0 ? net : 0;
  }

  /// Dana yang sedang ditahan sementara pada transaksi escrow aktif.
  int get escrowHeld =>
      (_useMock && !_syncedOnce) ? DemoData.escrowHeld.toInt() : _escrowHeld;

  int get activeOrderCount =>
      (_useMock && !_syncedOnce) ? 1 : _activeOrderCount;

  int get myServiceCount =>
      (_useMock && !_syncedOnce) ? DemoData.myServices.length : _myServiceCount;

  bool get isRefreshing => _refreshing;

  List<WalletMutation> get mutations {
    if (_useMock && !_syncedOnce) {
      return List.unmodifiable([
        ..._withdrawals,
        const WalletMutation(
          title: 'Dana Escrow Masuk',
          amountLabel: '+Rp 50.000',
          note: 'Spanduk Berkah Cibiru · Hari ini',
          incoming: true,
        ),
        const WalletMutation(
          title: 'Penarikan Dana',
          amountLabel: '-Rp 100.000',
          note: 'Transfer Rekening Mandiri · 8 Nov 2026',
        ),
      ]);
    }
    return List.unmodifiable([..._withdrawals, ..._orderMutations]);
  }

  /// Memperbarui ringkasan keuangan dari order penyedia & pelanggan yang real.
  void syncFromOrders({
    required List<EscrowOrderModel> providerOrders,
    required List<EscrowOrderModel> customerOrders,
    String? userId,
  }) {
    if (userId != null && userId.isNotEmpty && userId != _activeUserId) {
      _activeUserId = userId;
      _withdrawnTotal = 0;
      _withdrawals.clear();
    }

    _syncedOnce = true;

    _earnedBalance = providerOrders
        .where((o) => o.statusKode.toLowerCase() == 'completed')
        .fold<int>(0, (sum, o) => sum + o.harga);

    const terminalStatuses = {'completed', 'rejected', 'cancelled'};
    final seenOrderIds = <String>{};
    final combined = <EscrowOrderModel>[];
    for (final order in [...providerOrders, ...customerOrders]) {
      if (order.orderId.isEmpty || seenOrderIds.add(order.orderId)) {
        combined.add(order);
      }
    }

    final activeOrders = combined
        .where((o) => !terminalStatuses.contains(o.statusKode.toLowerCase()))
        .toList(growable: false);

    _activeOrderCount = activeOrders.length;
    _escrowHeld = activeOrders
        .where((o) => o.bolehLanjutInProgress)
        .fold<int>(0, (sum, o) => sum + o.harga);

    final mutations = <WalletMutation>[];
    for (final o in providerOrders) {
      if (o.statusKode.toLowerCase() == 'completed') {
        mutations.add(
          WalletMutation(
            title: 'Dana Escrow Dilepas',
            amountLabel: '+${formatRupiah(o.harga)}',
            note: '${o.judulLayanan} · ${o.kodePesanan}',
            incoming: true,
          ),
        );
      }
    }
    for (final o in customerOrders) {
      if (o.bolehLanjutInProgress ||
          o.statusKode.toLowerCase() == 'completed') {
        mutations.add(
          WalletMutation(
            title: 'Pembayaran Escrow (Simulasi)',
            amountLabel: '-${formatRupiah(o.harga)}',
            note: '${o.judulLayanan} · ${o.kodePesanan}',
          ),
        );
      }
    }
    _orderMutations = mutations;
    notifyListeners();
  }

  void setMyServiceCount(int count) {
    final normalized = count < 0 ? 0 : count;
    if (_myServiceCount == normalized && _syncedOnce) return;
    _myServiceCount = normalized;
    _syncedOnce = true;
    notifyListeners();
  }

  /// Menyegarkan saldo, escrow, dan jumlah layanan aktif langsung dari backend.
  Future<void> refreshLive({required EscrowRepository escrowRepository}) async {
    if (_useMock || _refreshing) return;
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) return;

    _refreshing = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        escrowRepository.fetchMyOrders(peran: 'pelanggan'),
        escrowRepository.fetchMyOrders(peran: 'penyedia'),
        _fetchMyListingsCount(token),
      ]);

      final custRes = results[0] as EscrowActionResult<List<EscrowOrderModel>>;
      final provRes = results[1] as EscrowActionResult<List<EscrowOrderModel>>;
      final serviceCount = results[2] as int?;

      if (serviceCount != null) {
        _myServiceCount = serviceCount;
      }

      if (!custRes.isFallback && !provRes.isFallback) {
        syncFromOrders(
          providerOrders: provRes.data,
          customerOrders: custRes.data,
          userId: AuthSession.instance.userId,
        );
      }
    } catch (_) {
      // Pertahankan state terakhir jika jaringan gagal
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<int?> _fetchMyListingsCount(String token) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/listings/me');
      final res = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(AppConfig.networkTimeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded['data'] as List<dynamic>? ?? const [];
        return list.length;
      }
    } catch (_) {}
    return null;
  }

  /// Memproses simulasi penarikan dana dan memperbarui riwayat mutasi serta
  /// saldo di seluruh aplikasi secara real-time. Mengembalikan pesan error jika
  /// tidak valid, atau `null` bila berhasil.
  String? simulateWithdraw({
    required int amount,
    required String methodLabel,
    required String destinationAccount,
  }) {
    final trimmedDest = destinationAccount.trim();
    if (trimmedDest.length < 4) {
      return 'Masukkan nomor rekening / e-wallet minimal 4 digit.';
    }
    if (amount <= 0) {
      return 'Nominal penarikan harus lebih dari Rp 0.';
    }
    if (availableBalance <= 0) {
      return 'Saldo pendapatan Anda masih Rp 0. Selesaikan pesanan sebagai penyedia jasa terlebih dahulu.';
    }
    if (amount > availableBalance) {
      return 'Saldo tidak mencukupi (tersedia ${formatRupiah(availableBalance)}).';
    }

    _withdrawnTotal += amount;
    _withdrawals.insert(
      0,
      WalletMutation(
        title: 'Penarikan Dana (Simulasi)',
        amountLabel: '-${formatRupiah(amount)}',
        note: '$methodLabel · $trimmedDest · Baru saja',
      ),
    );
    notifyListeners();
    return null;
  }

  /// Mereset seluruh state keuangan saat logout atau ganti akun.
  void resetForLogout() {
    _activeUserId = null;
    _earnedBalance = 0;
    _withdrawnTotal = 0;
    _escrowHeld = 0;
    _activeOrderCount = 0;
    _myServiceCount = 0;
    _syncedOnce = false;
    _refreshing = false;
    _withdrawals.clear();
    _orderMutations = const [];
    notifyListeners();
  }
}
