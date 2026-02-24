import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/app_router.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/features/draft/domain/entities/draft_rule.dart';
import 'package:app/features/draft/presentation/controllers/draft_selection_controller.dart';
import 'package:app/features/draft/presentation/state/draft_selection_state.dart';
import 'package:app/features/draft/presentation/widgets/draft_relation_widgets.dart';

class DraftRelationsPage extends ConsumerStatefulWidget {
  const DraftRelationsPage({
    super.key,
    required this.squadId,
    required this.selectedPlayerIds,
    this.initialDraftRules = const [],
    this.matchId,
    this.playWithSubstitute = true,
  });

  final String squadId;
  final List<String> selectedPlayerIds;
  final List<DraftRule> initialDraftRules;
  final String? matchId;
  final bool playWithSubstitute;

  @override
  ConsumerState<DraftRelationsPage> createState() => _DraftRelationsPageState();
}

class _DraftRelationsPageState extends ConsumerState<DraftRelationsPage> {
  late bool _playWithSubstitute;

  @override
  void initState() {
    super.initState();
    _playWithSubstitute = widget.playWithSubstitute;
    Future.microtask(
      () => ref
          .read(draftSelectionControllerProvider.notifier)
          .loadPlayers(
            squadId: widget.squadId,
            initialSelectedIds: widget.selectedPlayerIds,
            initialRules: widget.initialDraftRules,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftSelectionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relacja: Razem'),
        actions: [
          state.when(
            data: (data) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _goToAgainst(data: data),
                    child: const Text('Dalej'),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBody(error: error),
        data: (data) {
          final selected = data.players
              .where(
                (player) => data.selectedPlayerIds.contains(player.playerId),
              )
              .toList(growable: false);
          final playersById = {
            for (final player in selected) player.playerId: player,
          };

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wybierz graczy, którzy mają być razem w drużynie.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (data.validationMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InlineErrorText(message: data.validationMessage!),
                  ),
                Expanded(
                  child: DraftRelationGroupsList(
                    title: 'Relacje razem',
                    emptyText: 'Brak relacji „Razem”.',
                    groups: data.togetherGroups,
                    playersById: playersById,
                    borderColor: Colors.green,
                    onAdd: selected.length < 2
                        ? null
                        : () async {
                            final blockedIds = <String>{
                              ...data.togetherGroups.expand((group) => group),
                            };

                            final result = await showDraftRuleEditorDialog(
                              context: context,
                              title: 'Dodaj relację „Razem”',
                              players: selected,
                              blockedPlayerIds: blockedIds,
                              minSelection: 2,
                            );
                            if (result == null) {
                              return;
                            }

                            ref
                                .read(draftSelectionControllerProvider.notifier)
                                .upsertTogetherGroup(playerIds: result);
                          },
                    onEdit: (index) async {
                      final initialSelection = data.togetherGroups[index];
                      final blockedIds = <String>{
                        for (var i = 0; i < data.togetherGroups.length; i++)
                          if (i != index) ...data.togetherGroups[i],
                      };

                      final result = await showDraftRuleEditorDialog(
                        context: context,
                        title: 'Edytuj relację „Razem”',
                        players: selected,
                        blockedPlayerIds: blockedIds,
                        minSelection: 2,
                        initialSelection: initialSelection,
                      );
                      if (result == null) {
                        return;
                      }

                      ref
                          .read(draftSelectionControllerProvider.notifier)
                          .upsertTogetherGroup(playerIds: result, index: index);
                    },
                    onDelete: (index) => ref
                        .read(draftSelectionControllerProvider.notifier)
                        .removeTogetherGroup(index),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _goToAgainst({required DraftSelectionState data}) {
    context.pushNamed(
      AppRoute.draftAgainstRelations.name,
      pathParameters: {'squadId': widget.squadId},
      extra: {
        'selectedIds': data.selectedPlayerIds.toList(growable: false),
        'matchId': widget.matchId,
        'playWithSubstitute': _playWithSubstitute,
        'draftRules': serializeDraftRules(data.draftRules),
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final err = error;
    final message = err is Failure ? err.message : err.toString();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SelectableText.rich(
        TextSpan(
          text: message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

class _InlineErrorText extends StatelessWidget {
  const _InlineErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        text: message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
