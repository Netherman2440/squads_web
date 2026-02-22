enum DraftRuleType { together, against }

class DraftRule {
  final DraftRuleType type;
  final List<String> playerIds;

  const DraftRule({required this.type, required this.playerIds});
}
