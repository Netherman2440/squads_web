import 'package:app/features/players/domain/entities/player.dart';

class DraftSelectionState {
  final List<Player> players;
  final Set<String> selectedPlayerIds;
  final String searchQuery;
  final String? validationMessage;

  const DraftSelectionState({
    required this.players,
    required this.selectedPlayerIds,
    required this.searchQuery,
    this.validationMessage,
  });

  DraftSelectionState copyWith({
    List<Player>? players,
    Set<String>? selectedPlayerIds,
    String? searchQuery,
    String? validationMessage,
  }) {
    return DraftSelectionState(
      players: players ?? this.players,
      selectedPlayerIds: selectedPlayerIds ?? this.selectedPlayerIds,
      searchQuery: searchQuery ?? this.searchQuery,
      validationMessage: validationMessage,
    );
  }
}
