import '../../../../core/constants/campus_constants.dart';

enum EscrowStatus {
  draft,
  escrowLocked,
  inProgress,
  workSubmitted,
  completed,
  dispute,
  refunded,
}

class EscrowOrder {
  final String id;
  final String serviceId;
  final String serviceTitle;
  final ServiceCategory category;
  final String buyerId;
  final String sellerId;
  final int amount;
  final int platformFee; // Rp 0 for campus micro-economy
  final EscrowStatus status;
  final DateTime escrowLockedAt;
  final String? deliverableProofUrl;
  final String? deliverableNotes;
  final DateTime? workSubmittedAt;
  final DateTime? completedAt;

  const EscrowOrder({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.category,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    this.platformFee = 0,
    required this.status,
    required this.escrowLockedAt,
    this.deliverableProofUrl,
    this.deliverableNotes,
    this.workSubmittedAt,
    this.completedAt,
  });

  EscrowOrder copyWith({
    EscrowStatus? status,
    String? deliverableProofUrl,
    String? deliverableNotes,
    DateTime? workSubmittedAt,
    DateTime? completedAt,
  }) {
    return EscrowOrder(
      id: id,
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      category: category,
      buyerId: buyerId,
      sellerId: sellerId,
      amount: amount,
      platformFee: platformFee,
      status: status ?? this.status,
      escrowLockedAt: escrowLockedAt,
      deliverableProofUrl: deliverableProofUrl ?? this.deliverableProofUrl,
      deliverableNotes: deliverableNotes ?? this.deliverableNotes,
      workSubmittedAt: workSubmittedAt ?? this.workSubmittedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
