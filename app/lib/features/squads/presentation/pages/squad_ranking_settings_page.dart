import 'dart:math' as math;

import 'package:app/core/app_config.dart';
import 'package:app/features/squads/application/update_squad_ranking_settings_use_case.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/squad.dart';
import '../../domain/entities/user_squad_role.dart';

class SquadRankingSettingsPage extends ConsumerStatefulWidget {
  const SquadRankingSettingsPage({super.key, required this.squadId});

  final String squadId;

  @override
  ConsumerState<SquadRankingSettingsPage> createState() =>
      _SquadRankingSettingsPageState();
}

class _SquadRankingSettingsPageState
    extends ConsumerState<SquadRankingSettingsPage> {
  bool? _rankingUpdateDraft;
  bool? _useExperienceFactorDraft;
  double? _rankingMultiplierDraft;

  bool? _initialRankingUpdate;
  bool? _initialUseExperienceFactor;
  double? _initialRankingMultiplier;

  bool _isRankingUpdatesExpanded = false;
  bool _isExperienceFactorExpanded = false;

  static const double _maxContentWidth = 860;
  static const double _maxSliderWidth = 520;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final squadState = ref.watch(squadDetailProvider(widget.squadId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking settings'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isDirty ? _onSavePressed : null,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: squadState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                _RankingSettingsErrorView(error: error),
            data: (squad) {
              if (squad.role != SquadRole.owner) {
                return const _NoAccessView();
              }

              _ensureInitializedFromSquad(squad);

              final rankingUpdateDraft = _rankingUpdateDraft!;
              final useExperienceFactorDraft = _useExperienceFactorDraft!;
              final rankingMultiplierDraft = _rankingMultiplierDraft!;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage ranking updates',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Control how match results change player rankings.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),

                      _ActionDropdownRow(
                        title: 'Ranking updates',
                        subtitle: rankingUpdateDraft
                            ? 'Enabled. Match results update player rankings.'
                            : 'Disabled. Match results do not affect rankings.',
                        dropdownLabel: 'Change',
                        isExpanded: _isRankingUpdatesExpanded,
                        onToggleExpanded: () {
                          setState(() {
                            _isRankingUpdatesExpanded =
                                !_isRankingUpdatesExpanded;
                          });
                        },
                        optionLabel: rankingUpdateDraft
                            ? 'Disable ranking updates'
                            : 'Enable ranking updates',
                        onOptionPressed: () {
                          setState(() {
                            _rankingUpdateDraft = !rankingUpdateDraft;
                            _isRankingUpdatesExpanded = false;
                            _isExperienceFactorExpanded = false;
                            if (_rankingUpdateDraft == false) {
                              // Keep draft value, but hide controls when disabled.
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (rankingUpdateDraft) ...[
                        _ActionDropdownRow(
                          title: 'Experience factor',
                          subtitle: useExperienceFactorDraft
                              ? 'Enabled. New players gain/lose more.'
                              : 'Disabled. Everyone gets the same change.',
                          dropdownLabel: 'Change',
                          isExpanded: _isExperienceFactorExpanded,
                          onToggleExpanded: () {
                            setState(() {
                              _isExperienceFactorExpanded =
                                  !_isExperienceFactorExpanded;
                            });
                          },
                          optionLabel: useExperienceFactorDraft
                              ? 'Disable experience factor'
                              : 'Enable experience factor',
                          onOptionPressed: () {
                            setState(() {
                              _useExperienceFactorDraft =
                                  !useExperienceFactorDraft;
                              _isExperienceFactorExpanded = false;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _RankingPreview(
                          useExperienceFactorDraft: useExperienceFactorDraft,
                          rankingMultiplierDraft: rankingMultiplierDraft,
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final sliderWidth = math.min(
                              constraints.maxWidth,
                              _maxSliderWidth,
                            );
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: sliderWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Slider(
                                      value: _multiplierToSliderValue(
                                        rankingMultiplierDraft,
                                      ),
                                      min: 0,
                                      max: 2,
                                      divisions: 2,
                                      label: _multiplierLabel(
                                        rankingMultiplierDraft,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _rankingMultiplierDraft =
                                              _sliderValueToMultiplier(value);
                                        });
                                      },
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Small',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        Text(
                                          'Default',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        Text(
                                          'Big',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        Text(
                          'Ranking updates are currently disabled for this squad.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: _isDirty ? _onSavePressed : null,
                          child: const Text('Save changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _ensureInitializedFromSquad(Squad squad) {
    _rankingUpdateDraft ??= squad.rankingUpdate;
    _useExperienceFactorDraft ??= squad.useExperienceFactor;
    _rankingMultiplierDraft ??= squad.rankingMultiplier;

    _initialRankingUpdate ??= squad.rankingUpdate;
    _initialUseExperienceFactor ??= squad.useExperienceFactor;
    _initialRankingMultiplier ??= squad.rankingMultiplier;
  }

  bool get _isDirty =>
      _rankingUpdateDraft != _initialRankingUpdate ||
      _useExperienceFactorDraft != _initialUseExperienceFactor ||
      _rankingMultiplierDraft != _initialRankingMultiplier;

  Future<void> _onSavePressed() async {
    final rankingUpdate = _rankingUpdateDraft;
    final useExperienceFactor = _useExperienceFactorDraft;
    final rankingMultiplier = _rankingMultiplierDraft;

    if (rankingUpdate == null ||
        useExperienceFactor == null ||
        rankingMultiplier == null) {
      return;
    }

    await ref
        .read(updateSquadRankingSettingsUseCaseProvider)
        .execute(
          squadId: widget.squadId,
          rankingUpdate: rankingUpdate,
          rankingMultiplier: rankingMultiplier,
          useExperienceFactor: useExperienceFactor,
        );

    ref.invalidate(squadDetailProvider(widget.squadId));

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  static double _multiplierToSliderValue(double multiplier) {
    if (multiplier <= 0.75) return 0;
    if (multiplier <= 1.5) return 1;
    return 2;
  }

  static double _sliderValueToMultiplier(double value) {
    final rounded = value.round().clamp(0, 2);
    switch (rounded) {
      case 0:
        return 0.5;
      case 2:
        return 2.0;
      case 1:
      default:
        return 1.0;
    }
  }

  static String _multiplierLabel(double multiplier) {
    if (multiplier <= 0.75) return 'Small (0.5)';
    if (multiplier <= 1.5) return 'Default (1.0)';
    return 'Big (2.0)';
  }
}

class _RankingPreview extends StatelessWidget {
  const _RankingPreview({
    required this.useExperienceFactorDraft,
    required this.rankingMultiplierDraft,
  });

  final bool useExperienceFactorDraft;
  final double rankingMultiplierDraft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!useExperienceFactorDraft) {
      final changePerGoal = rankingMultiplierDraft;
      return Text(
        'Change per goal difference: ${changePerGoal.toStringAsFixed(2)}',
        style: theme.textTheme.bodySmall,
      );
    }

    final factor = AppConfig.experienceFactor;
    final newPlayer = rankingMultiplierDraft / (1 * factor);
    final experiencedPlayer = rankingMultiplierDraft / (10 * factor);
    final avg = (newPlayer + experiencedPlayer) / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avg change per goal difference: ${avg.toStringAsFixed(2)}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Examples: new player (1 match) ${newPlayer.toStringAsFixed(2)}, '
          'experienced (10 matches) ${experiencedPlayer.toStringAsFixed(2)}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _RankingSettingsErrorView extends StatelessWidget {
  const _RankingSettingsErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SelectableText.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Error\n\n',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAccessView extends StatelessWidget {
  const _NoAccessView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SelectableText.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'No access\n\n',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'Only the squad owner can edit ranking settings.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ActionDropdownRow extends StatelessWidget {
  const _ActionDropdownRow({
    required this.title,
    required this.subtitle,
    required this.dropdownLabel,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.optionLabel,
    required this.onOptionPressed,
  });

  final String title;
  final String subtitle;
  final String dropdownLabel;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final String optionLabel;
  final VoidCallback onOptionPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: onToggleExpanded,
                child: Text(dropdownLabel),
              ),
            ],
          ),
        ),
        if (isExpanded)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FilledButton.tonal(
                onPressed: onOptionPressed,
                child: Text(optionLabel),
              ),
            ),
          ),
      ],
    );
  }
}
