import 'package:app/features/draft/domain/entities/draft.dart';

class DraftProposal {
  final Draft draft;
  final double score;
  final double deviationScore;
  final double penaltyScore;
  final double rulePenalty;
  final double tieBreaker;
  final String signature;

  const DraftProposal({
    required this.draft,
    required this.score,
    required this.deviationScore,
    required this.penaltyScore,
    required this.rulePenalty,
    required this.tieBreaker,
    required this.signature,
  });

  DraftProposal copyWith({
    Draft? draft,
    double? score,
    double? deviationScore,
    double? penaltyScore,
    double? rulePenalty,
    double? tieBreaker,
    String? signature,
  }) {
    return DraftProposal(
      draft: draft ?? this.draft,
      score: score ?? this.score,
      deviationScore: deviationScore ?? this.deviationScore,
      penaltyScore: penaltyScore ?? this.penaltyScore,
      rulePenalty: rulePenalty ?? this.rulePenalty,
      tieBreaker: tieBreaker ?? this.tieBreaker,
      signature: signature ?? this.signature,
    );
  }
}
