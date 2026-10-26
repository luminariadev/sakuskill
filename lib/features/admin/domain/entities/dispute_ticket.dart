enum DisputeStatus {
  open,
  inReview,
  resolved,
}

enum ResolutionAction {
  refundToBuyer,
  releaseToSeller,
  split5050,
}

class DisputeTicket {
  final String id;
  final String transactionId;
  final String orderType; // ESCROW or BARTER
  final String raisedById;
  final String reason;
  final String evidenceNotes;
  final DisputeStatus status;
  final ResolutionAction? resolutionAction;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const DisputeTicket({
    required this.id,
    required this.transactionId,
    required this.orderType,
    required this.raisedById,
    required this.reason,
    required this.evidenceNotes,
    required this.status,
    this.resolutionAction,
    this.resolutionNotes,
    required this.createdAt,
    this.resolvedAt,
  });

  DisputeTicket copyWith({
    DisputeStatus? status,
    ResolutionAction? resolutionAction,
    String? resolutionNotes,
    DateTime? resolvedAt,
  }) {
    return DisputeTicket(
      id: id,
      transactionId: transactionId,
      orderType: orderType,
      raisedById: raisedById,
      reason: reason,
      evidenceNotes: evidenceNotes,
      status: status ?? this.status,
      resolutionAction: resolutionAction ?? this.resolutionAction,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
