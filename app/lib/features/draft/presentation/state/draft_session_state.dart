import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/players/domain/entities/player.dart';

class DraftSessionState {
  final List<Draft> proposals;
  final int selectedIndex;
  final int? seed;
  final List<Player> home;
  final List<Player> away;
  final Map<String, Map<String, double>> winRateMatrix;
  final double homeWinProbability;

  const DraftSessionState({
    required this.proposals,
    required this.selectedIndex,
    required this.seed,
    required this.home,
    required this.away,
    required this.winRateMatrix,
    required this.homeWinProbability,
  });

  DraftSessionState copyWith({
    List<Draft>? proposals,
    int? selectedIndex,
    int? seed,
    List<Player>? home,
    List<Player>? away,
    Map<String, Map<String, double>>? winRateMatrix,
    double? homeWinProbability,
  }) {
    return DraftSessionState(
      proposals: proposals ?? this.proposals,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      seed: seed ?? this.seed,
      home: home ?? this.home,
      away: away ?? this.away,
      winRateMatrix: winRateMatrix ?? this.winRateMatrix,
      homeWinProbability: homeWinProbability ?? this.homeWinProbability,
    );
  }
}
