import 'package:flutter/material.dart';

import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/players/domain/entities/player.dart';

class DraftRelationGroupsList extends StatelessWidget {
  const DraftRelationGroupsList({
    super.key,
    required this.title,
    required this.emptyText,
    required this.groups,
    required this.playersById,
    required this.borderColor,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String emptyText;
  final List<List<String>> groups;
  final Map<String, Player> playersById;
  final Color borderColor;
  final VoidCallback? onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Dodaj relację',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: groups.isEmpty
                  ? Text(
                      emptyText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  : ListView.separated(
                      itemCount: groups.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        final players = [
                          for (final playerId in group)
                            playersById[playerId] ??
                                Player(
                                  playerId: playerId,
                                  squadId: '',
                                  name: playerId,
                                  baseRanking: 0,
                                  ranking: 0,
                                  createdAt: DateTime(1970, 1, 1),
                                ),
                        ];

                        return _DraftRelationTile(
                          borderColor: borderColor,
                          players: players,
                          onEdit: () => onEdit(index),
                          onDelete: () => onDelete(index),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftRelationTile extends StatelessWidget {
  const _DraftRelationTile({
    required this.borderColor,
    required this.players,
    required this.onEdit,
    required this.onDelete,
  });

  final Color borderColor;
  final List<Player> players;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        color: borderColor.withValues(alpha: 0.06),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Edytuj',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Usuń',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            _RelationPlayersRows(players: players),
          ],
        ),
      ),
    );
  }
}

class _RelationPlayersRows extends StatelessWidget {
  const _RelationPlayersRows({required this.players});

  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const maxColumns = 3;
        final rows = <List<Player>>[];

        for (var start = 0; start < players.length; start += maxColumns) {
          final end = (start + maxColumns).clamp(0, players.length);
          rows.add(players.sublist(start, end));
        }

        return Column(
          children: [
            for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
              Row(
                children: [
                  for (
                    var playerIndex = 0;
                    playerIndex < rows[rowIndex].length;
                    playerIndex++
                  ) ...[
                    Expanded(
                      child: _RelationPlayerTile(
                        player: rows[rowIndex][playerIndex],
                      ),
                    ),
                    if (playerIndex != rows[rowIndex].length - 1)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
              if (rowIndex != rows.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _RelationPlayerTile extends StatelessWidget {
  const _RelationPlayerTile({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            child: Text(
              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              style: theme.textTheme.labelSmall,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ranking: ${player.ranking.toStringAsFixed(1)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<String>?> showDraftRuleEditorDialog({
  required BuildContext context,
  required String title,
  required List<Player> players,
  required Set<String> blockedPlayerIds,
  required int minSelection,
  Map<String, int> togetherGroupByPlayer = const {},
  bool blockTogetherConflicts = false,
  int? maxSelection,
  int? exactSelection,
  List<String> initialSelection = const [],
}) async {
  final availablePlayerIds = players.map((player) => player.playerId).toSet();
  final initial = initialSelection.where(availablePlayerIds.contains).toSet();

  return showDialog<List<String>>(
    context: context,
    builder: (dialogContext) {
      final selectedIds = <String>{...initial};

      return StatefulBuilder(
        builder: (context, setState) {
          final effectiveMaxSelection = exactSelection ?? maxSelection;
          final isValidSelection =
              selectedIds.length >= minSelection &&
              (exactSelection == null ||
                  selectedIds.length == exactSelection) &&
              (effectiveMaxSelection == null ||
                  selectedIds.length <= effectiveMaxSelection);

          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _buildSelectionHintText(
                      minSelection: minSelection,
                      maxSelection: effectiveMaxSelection,
                      exactSelection: exactSelection,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 320,
                    child: ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final player = players[index];
                        final playerId = player.playerId;
                        final isSelected = selectedIds.contains(playerId);
                        final isBlocked =
                            blockedPlayerIds.contains(playerId) && !isSelected;
                        final hasTogetherConflict =
                            blockTogetherConflicts &&
                            !isSelected &&
                            hasTogetherConflictForCandidate(
                              candidatePlayerId: playerId,
                              selectedPlayerIds: selectedIds,
                              togetherGroupByPlayer: togetherGroupByPlayer,
                            );
                        final reachesLimit =
                            effectiveMaxSelection != null &&
                            selectedIds.length >= effectiveMaxSelection;
                        final canSelect =
                            !isBlocked &&
                            !hasTogetherConflict &&
                            (!reachesLimit || isSelected);

                        return CheckboxListTile(
                          dense: true,
                          value: isSelected,
                          onChanged: !canSelect
                              ? null
                              : (value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedIds.add(playerId);
                                    } else {
                                      selectedIds.remove(playerId);
                                    }
                                  });
                                },
                          title: Text(player.name),
                          subtitle: Text(
                            'Ranking: ${player.ranking.toStringAsFixed(2)}',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: isValidSelection
                    ? () {
                        final ordered = [
                          for (final player in players)
                            if (selectedIds.contains(player.playerId))
                              player.playerId,
                        ];
                        Navigator.of(dialogContext).pop(ordered);
                      }
                    : null,
                child: const Text('Zapisz'),
              ),
            ],
          );
        },
      );
    },
  );
}

String _buildSelectionHintText({
  required int minSelection,
  required int? maxSelection,
  required int? exactSelection,
}) {
  if (exactSelection != null) {
    return 'Wybierz dokładnie $exactSelection graczy.';
  }
  if (maxSelection != null) {
    return 'Wybierz minimum $minSelection i maksymalnie $maxSelection graczy.';
  }
  return 'Wybierz minimum $minSelection graczy.';
}

Map<String, int> buildTogetherGroupByPlayer(List<List<String>> togetherGroups) {
  final result = <String, int>{};
  for (var groupIndex = 0; groupIndex < togetherGroups.length; groupIndex++) {
    for (final playerId in togetherGroups[groupIndex]) {
      result[playerId] = groupIndex;
    }
  }
  return result;
}

bool hasTogetherConflictForCandidate({
  required String candidatePlayerId,
  required Set<String> selectedPlayerIds,
  required Map<String, int> togetherGroupByPlayer,
}) {
  final candidateGroup = togetherGroupByPlayer[candidatePlayerId];
  if (candidateGroup == null) {
    return false;
  }

  for (final selectedPlayerId in selectedPlayerIds) {
    if (selectedPlayerId == candidatePlayerId) {
      continue;
    }
    if (togetherGroupByPlayer[selectedPlayerId] == candidateGroup) {
      return true;
    }
  }

  return false;
}

List<Map<String, dynamic>> serializeDraftRules(List<DraftRule> rules) {
  return [
    for (final rule in rules)
      {'type': rule.type.name, 'playerIds': rule.playerIds},
  ];
}
