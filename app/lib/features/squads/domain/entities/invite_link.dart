class InviteLink {
  final String code;
  final String squadId;
  final DateTime createdAt;
  final DateTime validUntil;
  final String createdBy;

  const InviteLink({
    required this.code,
    required this.squadId,
    required this.createdAt,
    required this.validUntil,
    required this.createdBy,
  });

  bool get isExpired => validUntil.isBefore(DateTime.now());

  factory InviteLink.fromMap(Map<String, dynamic> map) {
    return InviteLink(
      code: map['code'] as String,
      squadId: map['squad_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      validUntil: DateTime.parse(map['valid_until'] as String),
      createdBy: map['created_by'] as String,
    );
  }
}
