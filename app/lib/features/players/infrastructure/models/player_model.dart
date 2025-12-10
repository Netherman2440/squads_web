import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/player.dart';

part 'player_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class PlayerModel {
  PlayerModel({
    required this.playerId,
    required this.squadId,
    required this.name,
    required this.position,
    required this.baseScore,
    required this.score,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) =>
      _$PlayerModelFromJson(json);

  factory PlayerModel.fromDomain(Player player) {
    return PlayerModel(
      playerId: player.id,
      squadId: player.squadId,
      name: player.name,
      position: player.position,
      baseScore: player.baseScore,
      score: player.score,
      createdAt: player.createdAt,
      updatedAt: player.updatedAt,
      isDeleted: player.isDeleted,
    );
  }

  final String playerId;
  final String squadId;
  final String name;
  final String? position;
  final int baseScore;
  final double score;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Player toDomain() {
    return Player(
      id: playerId,
      squadId: squadId,
      name: name,
      position: position,
      baseScore: baseScore,
      score: score,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() => _$PlayerModelToJson(this);
}
