import 'package:app/features/draft/domain/entities/draft_rule.dart';

List<Map<String, dynamic>> encodeDraftRules(List<DraftRule> rules) {
  return [
    for (final rule in rules)
      {'type': rule.type.name, 'playerIds': rule.playerIds},
  ];
}

List<DraftRule> decodeDraftRules(Object? rawRules) {
  if (rawRules is! List) {
    return const [];
  }

  final rules = <DraftRule>[];
  for (final entry in rawRules) {
    if (entry is! Map) {
      continue;
    }

    final map = Map<String, dynamic>.from(entry);
    final typeRaw = map['type'];
    final playerIdsRaw = map['playerIds'];
    if (typeRaw is! String || playerIdsRaw is! List) {
      continue;
    }

    final type = switch (typeRaw) {
      'together' => DraftRuleType.together,
      'against' => DraftRuleType.against,
      _ => null,
    };
    if (type == null) {
      continue;
    }

    final ids = playerIdsRaw.whereType<String>().toSet().toList(
      growable: false,
    );
    if (ids.length < 2) {
      continue;
    }

    rules.add(DraftRule(type: type, playerIds: ids));
  }

  return rules;
}

List<List<String>> togetherGroupsFromRules(List<DraftRule> rules) {
  return [
    for (final rule in rules)
      if (rule.type == DraftRuleType.together) rule.playerIds,
  ];
}

List<List<String>> againstGroupsFromRules(List<DraftRule> rules) {
  return [
    for (final rule in rules)
      if (rule.type == DraftRuleType.against) rule.playerIds,
  ];
}

List<DraftRule> composeRules({
  required List<List<String>> togetherGroups,
  required List<List<String>> againstGroups,
}) {
  return [
    ...togetherGroups.map(
      (group) => DraftRule(type: DraftRuleType.together, playerIds: group),
    ),
    ...againstGroups.map(
      (group) => DraftRule(type: DraftRuleType.against, playerIds: group),
    ),
  ];
}

String? validateDraftGroups({
  required Set<String> selectedPlayerIds,
  required int teamCount,
  required List<List<String>> togetherGroups,
  required List<List<String>> againstGroups,
}) {
  final togetherPlayerToGroup = <String, int>{};
  for (var groupIndex = 0; groupIndex < togetherGroups.length; groupIndex++) {
    final group = togetherGroups[groupIndex];
    if (group.length < 2) {
      return 'Together group must contain at least 2 players.';
    }

    for (final playerId in group) {
      if (!selectedPlayerIds.contains(playerId)) {
        return 'Rules can only contain selected players.';
      }

      final existingGroup = togetherPlayerToGroup[playerId];
      if (existingGroup != null && existingGroup != groupIndex) {
        return 'A player cannot belong to multiple together groups.';
      }
      togetherPlayerToGroup[playerId] = groupIndex;
    }
  }

  for (final group in againstGroups) {
    if (group.toSet().length != group.length) {
      return 'Against group cannot contain duplicates.';
    }
    if (group.length != teamCount) {
      return 'Against group must contain exactly $teamCount players.';
    }

    final togetherGroupsInAgainst = <int>{};
    for (final playerId in group) {
      if (!selectedPlayerIds.contains(playerId)) {
        return 'Rules can only contain selected players.';
      }

      final togetherGroupIndex = togetherPlayerToGroup[playerId];
      if (togetherGroupIndex != null &&
          !togetherGroupsInAgainst.add(togetherGroupIndex)) {
        return 'Against group cannot contain players from same together group.';
      }
    }
  }

  return null;
}
