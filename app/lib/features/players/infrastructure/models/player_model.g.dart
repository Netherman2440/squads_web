// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_model.dart';

PlayerModel _$PlayerModelFromJson(Map<String, dynamic> json) => PlayerModel(
      playerId: json['player_id'] as String,
      squadId: json['squad_id'] as String,
      name: json['name'] as String,
      position: json['position'] as String?,
      baseScore: (json['base_score'] as num).toInt(),
      score: (json['score'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isDeleted: json['is_deleted'] as bool,
    );

Map<String, dynamic> _$PlayerModelToJson(PlayerModel instance) =>
    <String, dynamic>{
      'player_id': instance.playerId,
      'squad_id': instance.squadId,
      'name': instance.name,
      'position': instance.position,
      'base_score': instance.baseScore,
      'score': instance.score,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'is_deleted': instance.isDeleted,
    };
