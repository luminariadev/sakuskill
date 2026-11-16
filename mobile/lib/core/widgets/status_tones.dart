import 'package:material_ui/material_ui.dart';

import '../domain/status.dart';
import 'saku_pill.dart';

/// Pemetaan enum status baku → warna [SakuPill] (lapisan presentasi; domain
/// tetap bebas Flutter).
///
/// Bahasa warna: hijau = berhasil/selesai, biru = berjalan/escrow,
/// amber = menunggu tindakan, ungu = barter, merah = ditolak/sengketa,
/// abu = netral/dibatalkan.
extension OrderStatusTone on OrderStatus {
  SakuPillTone get tone => switch (this) {
        OrderStatus.submitted => SakuPillTone.escrow,
        OrderStatus.rejected => SakuPillTone.dispute,
        OrderStatus.negotiating => SakuPillTone.integrity,
        OrderStatus.agreed => SakuPillTone.primary,
        OrderStatus.paid => SakuPillTone.escrow,
        OrderStatus.inProgress => SakuPillTone.escrow,
        OrderStatus.awaitingConfirmation => SakuPillTone.integrity,
        OrderStatus.completed => SakuPillTone.primary,
        OrderStatus.cancelled => SakuPillTone.neutral,
        OrderStatus.disputed => SakuPillTone.dispute,
      };
}

extension BarterStatusTone on BarterStatus {
  SakuPillTone get tone => switch (this) {
        BarterStatus.submitted ||
        BarterStatus.discussing ||
        BarterStatus.agreed ||
        BarterStatus.executing =>
          SakuPillTone.barter,
        BarterStatus.rejected || BarterStatus.disputed => SakuPillTone.dispute,
        BarterStatus.completed => SakuPillTone.primary,
        BarterStatus.cancelled => SakuPillTone.neutral,
      };
}

extension BarterExecStatusTone on BarterExecStatus {
  SakuPillTone get tone => switch (this) {
        BarterExecStatus.notStarted => SakuPillTone.neutral,
        BarterExecStatus.inProgress => SakuPillTone.barter,
        BarterExecStatus.done => SakuPillTone.primary,
      };
}

extension PaymentStatusTone on PaymentStatus {
  SakuPillTone get tone => switch (this) {
        PaymentStatus.awaitingPayment => SakuPillTone.integrity,
        PaymentStatus.awaitingVerification => SakuPillTone.escrow,
        PaymentStatus.verified => SakuPillTone.primary,
        PaymentStatus.failed => SakuPillTone.dispute,
        PaymentStatus.cancelled => SakuPillTone.neutral,
      };
}

extension EscrowSimStatusTone on EscrowSimStatus {
  SakuPillTone get tone => switch (this) {
        EscrowSimStatus.noFunds => SakuPillTone.neutral,
        EscrowSimStatus.held => SakuPillTone.escrow,
        EscrowSimStatus.released => SakuPillTone.primary,
        EscrowSimStatus.refunded => SakuPillTone.integrity,
      };
}

extension ReportStatusTone on ReportStatus {
  SakuPillTone get tone => switch (this) {
        ReportStatus.submitted => SakuPillTone.integrity,
        ReportStatus.reviewing => SakuPillTone.escrow,
        ReportStatus.resolved => SakuPillTone.primary,
      };
}

extension VerificationStatusTone on VerificationStatus {
  SakuPillTone get tone => switch (this) {
        VerificationStatus.unverified => SakuPillTone.neutral,
        VerificationStatus.verified => SakuPillTone.primary,
        VerificationStatus.rejected => SakuPillTone.dispute,
      };
}

extension OfferTypeTone on OfferType {
  SakuPillTone get tone => switch (this) {
        OfferType.paid => SakuPillTone.primary,
        OfferType.barter || OfferType.paidAndBarter => SakuPillTone.barter,
      };
}

/// Warna pill untuk enum status baku apa pun.
SakuPillTone statusTone(ApiEnum status) => switch (status) {
      OrderStatus s => s.tone,
      BarterStatus s => s.tone,
      BarterExecStatus s => s.tone,
      PaymentStatus s => s.tone,
      EscrowSimStatus s => s.tone,
      ReportStatus s => s.tone,
      VerificationStatus s => s.tone,
      OfferType s => s.tone,
      _ => SakuPillTone.neutral,
    };

/// Badge status baku: label dari enum + warna dari [statusTone].
///
/// ```dart
/// StatusPill(OrderStatus.fromJson(json['status_pesanan']))
/// StatusPill(EscrowSimStatus.held) // + keterangan simulasi (FR-59)
/// ```
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key, this.dense = false});

  final ApiEnum status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: ${status.label}',
      excludeSemantics: true,
      child: SakuPill(label: status.label, tone: statusTone(status), dense: dense),
    );
  }
}
