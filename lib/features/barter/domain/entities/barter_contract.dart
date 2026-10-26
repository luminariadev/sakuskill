enum BarterStatus {
  proposed,
  partiallySubmitted,
  bothSubmitted,
  completed,
  disputed,
}

class BarterContract {
  final String id;
  final String initiatorId;
  final String initiatorServiceTitle;
  final String? initiatorDeliverableProof;
  final bool initiatorApproved;

  final String partnerId;
  final String partnerServiceTitle;
  final String? partnerDeliverableProof;
  final bool partnerApproved;

  final String termsAndAgreement;
  final BarterStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  const BarterContract({
    required this.id,
    required this.initiatorId,
    required this.initiatorServiceTitle,
    this.initiatorDeliverableProof,
    required this.initiatorApproved,
    required this.partnerId,
    required this.partnerServiceTitle,
    this.partnerDeliverableProof,
    required this.partnerApproved,
    required this.termsAndAgreement,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  BarterContract copyWith({
    String? initiatorDeliverableProof,
    bool? initiatorApproved,
    String? partnerDeliverableProof,
    bool? partnerApproved,
    BarterStatus? status,
    DateTime? completedAt,
  }) {
    return BarterContract(
      id: id,
      initiatorId: initiatorId,
      initiatorServiceTitle: initiatorServiceTitle,
      initiatorDeliverableProof: initiatorDeliverableProof ?? this.initiatorDeliverableProof,
      initiatorApproved: initiatorApproved ?? this.initiatorApproved,
      partnerId: partnerId,
      partnerServiceTitle: partnerServiceTitle,
      partnerDeliverableProof: partnerDeliverableProof ?? this.partnerDeliverableProof,
      partnerApproved: partnerApproved ?? this.partnerApproved,
      termsAndAgreement: termsAndAgreement,
      status: status ?? this.status,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
