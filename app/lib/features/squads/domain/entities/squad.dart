import 'package:app/features/squads/domain/entities/user_squad_role.dart';

enum SquadVisibility {
  public,
  private,
}

enum SportType {
  football,
}

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

  String get label => name;
}

extension SportTypeParser on SportType {
  static SportType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'football':
      default:
        return SportType.football;
    }
  }

  String get label => name;
}

class Squad {
  final String squadId;
  final String ownerId;
  final String name;
  final SquadVisibility visibility;
  final SportType sportType;
  final DateTime createdAt;
  final int memberCount;
  final SquadRole role;

  const Squad({
    required this.squadId,
    required this.ownerId,
    required this.name,
    required this.visibility,
    required this.sportType,
    required this.createdAt,
    required this.memberCount,
    this.role = SquadRole.none,
  });

  Squad copyWith({
    String? squadId,
    String? ownerId,
    String? name,
    SquadVisibility? visibility,
    SportType? sportType,
    DateTime? createdAt,
    int? memberCount,
    SquadRole? role,
  }) {
    return Squad(
      squadId: squadId ?? this.squadId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      visibility: visibility ?? this.visibility,
      sportType: sportType ?? this.sportType,
      createdAt: createdAt ?? this.createdAt,
      memberCount: memberCount ?? this.memberCount,
      role: role ?? this.role,
    );
  }

  factory Squad.fromMap(Map<String, dynamic> map) {
    final dynamic memberCountValue =
        map['member_count'] ?? map['user_squads']?.first?['count'];

    return Squad(
      squadId: map['squad_id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String,
      visibility:
          SquadVisibilityParser.fromString(map['visibility'] as String?),
      sportType: SportTypeParser.fromString(map['sport_type'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      memberCount: memberCountValue is int
          ? memberCountValue
          : int.tryParse(memberCountValue?.toString() ?? '') ?? 0,
      role: SquadRoleParser.fromString(map['role'] as String?),
    );
  }

  Map<String, dynamic> toMap() => {
        'squad_id': squadId,
        'owner_id': ownerId,
        'name': name,
        'visibility': visibility.name,
        'sport_type': sportType.name,
        'created_at': createdAt.toIso8601String(),
        'member_count': memberCount,
        'role': role.name,
      };
}
