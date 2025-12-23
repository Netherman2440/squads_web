import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/players/domain/entities/player.dart';

class DraftSessionState {
  final List<Draft> proposals;
  final int selectedIndex;
  final List<Player> home;
  final List<Player> away;

  const DraftSessionState({
    required this.proposals,
    required this.selectedIndex,
    required this.home,
    required this.away,
  });

  DraftSessionState copyWith({
    List<Draft>? proposals,
    int? selectedIndex,
    List<Player>? home,
    List<Player>? away,
  }) {
    return DraftSessionState(
      proposals: proposals ?? this.proposals,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      home: home ?? this.home,
      away: away ?? this.away,
    );
  }
}
