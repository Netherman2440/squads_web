import 'package:app/features/draft/domain/entities/draft.dart';

class DraftProposal {
  final Draft draft;
  final double score;
  final double rulePenalty;
  final double tieBreaker;
  final String signature;

  const DraftProposal({
    required this.draft,
    required this.score,
    required this.rulePenalty,
    required this.tieBreaker,
    required this.signature,
  });
}
