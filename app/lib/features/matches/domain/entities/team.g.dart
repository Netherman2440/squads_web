// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Team _$TeamFromJson(Map<String, dynamic> json) => Team(
  teamId: json['team_id'] as String,
  matchId: json['match_id'] as String,
  side: $enumDecode(_$SideEnumMap, json['side']),
  name: json['name'] as String?,
  color: json['color'] as String?,
  players: json['players'] == null
      ? const []
      : _playersFromJson(json['players'] as List),
);

Map<String, dynamic> _$TeamToJson(Team instance) => <String, dynamic>{
  'team_id': instance.teamId,
  'match_id': instance.matchId,
  'side': _$SideEnumMap[instance.side]!,
  'name': instance.name,
  'color': instance.color,
  'players': _playersToJson(instance.players),
};

const _$SideEnumMap = {Side.home: 'home', Side.away: 'away'};
