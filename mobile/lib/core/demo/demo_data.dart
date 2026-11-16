import 'demo_assets.dart';

/// Data demo alur transaksi dari Figma "User Design" (pesanan #SK-091,
/// kontrak barter #BTR-012, percakapan, jasa saya, dompet).
///
/// Modul escrow/barter belum punya API, jadi layar-layar alur memakai data
/// ini. Saat backend siap, ganti dengan repository masing-masing modul.
abstract final class DemoData {
  static const String me = 'Salma Nur Oktavia';
  static const num balance = 250000;
  static const num escrowHeld = 50000;

  static const order = DemoOrder(
    code: '#SK-091',
    title: 'Desain Spanduk Toko 3×1 m',
    serviceTitle: 'Jasa Desain Spanduk Toko & Banner Promosi',
    amount: 50000,
    client: 'Dimas',
    clientLabel: 'Dimas (Katering Berkah)',
    clientAsset: DemoAssets.dimas,
    provider: me,
    providerAsset: DemoAssets.salma,
    deadlineDays: 3,
  );

  static const barter = DemoBarter(
    code: '#BTR-012',
    partner: 'Rizkia Nuari',
    partnerAsset: DemoAssets.rizkia,
    mySkill: 'Desain Web',
    partnerSkill: 'Video Reels 30 Detik',
    myProgress: 0.75,
    partnerProgress: 0.60,
  );

  static const conversations = <DemoConversation>[
    DemoConversation(
      name: 'Dimas (Katering Berkah Cibiru)',
      subtitle: 'Klien · Spanduk 3×1 m',
      asset: DemoAssets.dimas,
      contextLabel: 'PESANAN #SK-091 (SPANDUK)',
      kind: ConversationKind.escrow,
      lastMessage:
          'Baik Mbak Salma, saya setuju spanduk 3×1 m. Saya langsung proses escrow ya.',
      time: '10:15',
      unread: 1,
    ),
    DemoConversation(
      name: 'Rizkia Nuari',
      subtitle: 'Mitra barter',
      asset: DemoAssets.rizkia,
      contextLabel: 'KONTRAK BARTER #BTR-012',
      kind: ConversationKind.barter,
      lastMessage:
          'Deal! Saya konfirmasi kesepakatan tukar video dan desain web sekarang.',
      time: 'Kemarin',
    ),
    DemoConversation(
      name: 'Admin Mediasi SakuSkill',
      subtitle: 'Customer support',
      kind: ConversationKind.support,
      lastMessage: 'Laporan transaksi Anda telah selesai ditinjau.',
      time: '3 Hari Lalu',
    ),
  ];

  static const myServices = <DemoService>[
    DemoService(
      title: 'Jasa Desain Spanduk Toko & Banner Promosi',
      priceLabel: 'Rp 50.000 / Proyek',
      days: 3,
      stats: '142x Dilihat · 19 Pesanan Selesai · 4.9 ★',
      cover: DemoAssets.spandukBerkah,
    ),
    DemoService(
      title: 'Desain Feed & Story Instagram Promosi (Paket 6 Feed)',
      priceLabel: 'Rp 75.000 / Paket',
      days: 2,
      stats: '88x Dilihat · 7 Pesanan Selesai · 5.0 ★',
      cover: DemoAssets.portfolioInstagram,
      barter: true,
    ),
  ];
}

class DemoOrder {
  const DemoOrder({
    required this.code,
    required this.title,
    required this.serviceTitle,
    required this.amount,
    required this.client,
    required this.clientLabel,
    required this.clientAsset,
    required this.provider,
    required this.providerAsset,
    required this.deadlineDays,
  });

  final String code;
  final String title;
  final String serviceTitle;
  final num amount;
  final String client;
  final String clientLabel;
  final String clientAsset;
  final String provider;
  final String providerAsset;
  final int deadlineDays;
}

class DemoBarter {
  const DemoBarter({
    required this.code,
    required this.partner,
    required this.partnerAsset,
    required this.mySkill,
    required this.partnerSkill,
    required this.myProgress,
    required this.partnerProgress,
  });

  final String code;
  final String partner;
  final String partnerAsset;
  final String mySkill;
  final String partnerSkill;
  final double myProgress;
  final double partnerProgress;
}

enum ConversationKind { escrow, barter, support }

class DemoConversation {
  const DemoConversation({
    required this.name,
    required this.subtitle,
    required this.kind,
    required this.lastMessage,
    required this.time,
    this.asset,
    this.contextLabel,
    this.unread = 0,
  });

  final String name;
  final String subtitle;
  final String? asset;
  final String? contextLabel;
  final ConversationKind kind;
  final String lastMessage;
  final String time;
  final int unread;
}

class DemoService {
  const DemoService({
    required this.title,
    required this.priceLabel,
    required this.days,
    required this.stats,
    required this.cover,
    this.barter = false,
  });

  final String title;
  final String priceLabel;
  final int days;
  final String stats;
  final String cover;
  final bool barter;
}
