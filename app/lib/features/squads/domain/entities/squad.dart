import 'package:app/features/squads/domain/entities/user_squad_role.dart';

enum SquadVisibility { public, private }

enum SportType { football }

extension SquadVisibilityParser on SquadVisibility {
  static SquadVisibility fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'private':
        return SquadVisibility.private;
      case 'public':
      default:
        return SquadVisibility.public;
    }
  }

  String get label {
    switch (this) {
      case SquadVisibility.public:
        return 'Publiczny';
      case SquadVisibility.private:
        return 'Prywatny';
    }
  }
}

extension SportTypeParser on SportType {
  static SportType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'football':
      default:
        return SportType.football;
    }
  }

  String get label {
    switch (this) {
      case SportType.football:
        return 'Piłka nożna';
    }
  }
}

class Squad {
  final String squadId;
  final String ownerId;
  final String name;
  final SquadVisibility visibility;
  final SportType sportType;
  final DateTime createdAt;
  final SquadRole role;

  /// True when squad has at least one member with `pending` role.
  ///
  /// This is derived from memberships, not stored on `squads` table.
  final bool hasPendingMembers;

  final bool rankingUpdate;
  final int rankingMultiplier;
  final bool useExperienceFactor;

  const Squad({
    required this.squadId,
    required this.ownerId,
    required this.name,
    required this.visibility,
    required this.sportType,
    required this.createdAt,
    this.role = SquadRole.none,
    this.hasPendingMembers = false,
    this.rankingUpdate = true,
    this.rankingMultiplier = 5,
    this.useExperienceFactor = true,
  });

  Squad copyWith({
    String? squadId,
    String? ownerId,
    String? name,
    SquadVisibility? visibility,
    SportType? sportType,
    DateTime? createdAt,
    SquadRole? role,
    bool? hasPendingMembers,
    bool? rankingUpdate,
    int? rankingMultiplier,
    bool? useExperienceFactor,
  }) {
    return Squad(
      squadId: squadId ?? this.squadId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      visibility: visibility ?? this.visibility,
      sportType: sportType ?? this.sportType,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      hasPendingMembers: hasPendingMembers ?? this.hasPendingMembers,
      rankingUpdate: rankingUpdate ?? this.rankingUpdate,
      rankingMultiplier: rankingMultiplier ?? this.rankingMultiplier,
      useExperienceFactor: useExperienceFactor ?? this.useExperienceFactor,
    );
  }

  factory Squad.fromMap(Map<String, dynamic> map) {
    return Squad(
      squadId: map['squad_id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String,
      visibility: SquadVisibilityParser.fromString(
        map['visibility'] as String?,
      ),
      sportType: SportTypeParser.fromString(map['sport_type'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      role: SquadRoleParser.fromString(map['role'] as String?),
      hasPendingMembers: false,
      rankingUpdate: map['ranking_update'] as bool? ?? true,
      rankingMultiplier: map['ranking_multiplier'] as int? ?? 5,
      useExperienceFactor: map['use_experience_factor'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'squad_id': squadId,
    'owner_id': ownerId,
    'name': name,
    'visibility': visibility.name,
    'sport_type': sportType.name,
    'created_at': createdAt.toIso8601String(),
    'role': role.name,
    'has_pending_members': hasPendingMembers,
    'ranking_update': rankingUpdate,
    'ranking_multiplier': rankingMultiplier,
    'use_experience_factor': useExperienceFactor,
  };
}
