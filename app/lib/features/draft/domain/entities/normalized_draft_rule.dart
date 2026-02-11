import 'package:app/features/draft/domain/entities/draft_rule.dart';

class NormalizedDraftRule {
  final DraftRuleType type;
  final List<int> playerIndexes;

  const NormalizedDraftRule({required this.type, required this.playerIndexes});
}
