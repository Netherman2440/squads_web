import 'package:app/features/tournaments/domain/entities/tournament_status.dart';

class Tournament {
  final String tournamentId;
  final String squadId;
  final String? name;
  final TournamentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? acceptedTournamentDraftId;

  const Tournament({
    required this.tournamentId,
    required this.squadId,
    this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedTournamentDraftId,
  });

  Tournament copyWith({
    String? tournamentId,
    String? squadId,
    String? name,
    TournamentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? acceptedTournamentDraftId,
  }) {
    return Tournament(
      tournamentId: tournamentId ?? this.tournamentId,
      squadId: squadId ?? this.squadId,
      name: name ?? this.name,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedTournamentDraftId:
          acceptedTournamentDraftId ?? this.acceptedTournamentDraftId,
    );
  }

  factory Tournament.fromMap(Map<String, dynamic> map) {
    return Tournament(
      tournamentId: map['tournament_id'] as String,
      squadId: map['squad_id'] as String,
      name: map['name'] as String?,
      status: TournamentStatusParser.fromString(map['status'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      acceptedTournamentDraftId:
          map['accepted_tournament_draft_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tournament_id': tournamentId,
      'squad_id': squadId,
      'name': name,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'accepted_tournament_draft_id': acceptedTournamentDraftId,
    };
  }
}
