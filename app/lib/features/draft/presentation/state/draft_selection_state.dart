import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/players/domain/entities/player.dart';

class DraftSelectionState {
  final List<Player> players;
  final Set<String> selectedPlayerIds;
  final List<List<String>> togetherGroups;
  final List<List<String>> againstGroups;
  final int teamCount;
  final String searchQuery;
  final String? validationMessage;

  const DraftSelectionState({
    required this.players,
    required this.selectedPlayerIds,
    required this.togetherGroups,
    required this.againstGroups,
    required this.teamCount,
    required this.searchQuery,
    this.validationMessage,
  });

  List<DraftRule> get draftRules => [
    ...togetherGroups.map(
      (group) => DraftRule(type: DraftRuleType.together, playerIds: group),
    ),
    ...againstGroups.map(
      (group) => DraftRule(type: DraftRuleType.against, playerIds: group),
    ),
  ];

  DraftSelectionState copyWith({
    List<Player>? players,
    Set<String>? selectedPlayerIds,
    List<List<String>>? togetherGroups,
    List<List<String>>? againstGroups,
    int? teamCount,
    String? searchQuery,
    Object? validationMessage = _validationUnchanged,
  }) {
    return DraftSelectionState(
      players: players ?? this.players,
      selectedPlayerIds: selectedPlayerIds ?? this.selectedPlayerIds,
      togetherGroups: togetherGroups ?? this.togetherGroups,
      againstGroups: againstGroups ?? this.againstGroups,
      teamCount: teamCount ?? this.teamCount,
      searchQuery: searchQuery ?? this.searchQuery,
      validationMessage: identical(validationMessage, _validationUnchanged)
          ? this.validationMessage
          : validationMessage as String?,
    );
  }
}

const Object _validationUnchanged = Object();
