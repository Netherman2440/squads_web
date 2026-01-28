import 'dart:math' as math;

import 'package:app/core/app_config.dart';
import 'package:app/core/widgets/danger_action_button.dart';
import 'package:app/features/squads/application/update_squad_ranking_settings_use_case.dart';
import 'package:app/features/squads/presentation/state/squad_detail_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int? _rankingMultiplierDraft;

  bool? _initialRankingUpdate;
  bool? _initialUseExperienceFactor;
  int? _initialRankingMultiplier;

  bool _isRankingUpdatesExpanded = false;
  bool _isExperienceFactorExpanded = false;
  bool _keepTestPreviewVisibleUntilSave = false;

  static const double _maxContentWidth = 860;
  static const double _maxSliderWidth = 520;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final squadState = ref.watch(squadDetailProvider(widget.squadId));

    return Scaffold(
      appBar: AppBar(title: const Text('Ranking settings')),
      body: SafeArea(
        child: SingleChildScrollView(
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
                            ? 'Disable updates'
                            : 'Enable updates',
                        onOptionPressed: () async {
                          setState(() {
                            _rankingUpdateDraft = !rankingUpdateDraft;
                            _isRankingUpdatesExpanded = false;
                            _isExperienceFactorExpanded = false;
                            if (_rankingUpdateDraft == false) {
                              // Keep draft value, but hide controls when disabled.
                            }
                          });
                          await _saveToggles(
                            rankingUpdate: _rankingUpdateDraft!,
                            useExperienceFactor: _initialUseExperienceFactor!,
                          );
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
                          onOptionPressed: () async {
                            setState(() {
                              _useExperienceFactorDraft =
                                  !useExperienceFactorDraft;
                              _isExperienceFactorExpanded = false;
                            });
                            await _saveToggles(
                              rankingUpdate: _initialRankingUpdate!,
                              useExperienceFactor: _useExperienceFactorDraft!,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final sliderWidth = math.min(
                              constraints.maxWidth,
                              _maxSliderWidth,
                            );
                            final rankingMultiplierDraft =
                                _rankingMultiplierDraft ?? 5;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Factor value',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: sliderWidth,
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                '1',
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Slider(
                                                  value: rankingMultiplierDraft
                                                      .toDouble(),
                                                  min: 1,
                                                  max: 10,
                                                  divisions: 9,
                                                  label: rankingMultiplierDraft
                                                      .toString(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _rankingMultiplierDraft =
                                                          value.round().clamp(
                                                            1,
                                                            10,
                                                          );
                                                      if (_isMultiplierDirty) {
                                                        _keepTestPreviewVisibleUntilSave =
                                                            true;
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                              Text(
                                                '10',
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (_keepTestPreviewVisibleUntilSave) ...[
                                        const SizedBox(width: 12),
                                        FilledButton(
                                          onPressed: _onSaveMultiplierPressed,
                                          child: const Text('Save'),
                                        ),
                                      ],
                                    ],
                                  ),

                                  if (_keepTestPreviewVisibleUntilSave) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'Test new settings out',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: sliderWidth,
                                      child: _TestMatchPreview(
                                        useExperienceFactor:
                                            useExperienceFactorDraft,
                                        rankingMultiplier:
                                            rankingMultiplierDraft,
                                      ),
                                    ),
                                  ],
                                ],
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

  bool get _isMultiplierDirty =>
      _rankingMultiplierDraft != null &&
      _initialRankingMultiplier != null &&
      _rankingMultiplierDraft != _initialRankingMultiplier;

  Future<void> _saveRankingSettings({
    required bool rankingUpdate,
    required bool useExperienceFactor,
    required int rankingMultiplier,
  }) async {
    await ref
        .read(updateSquadRankingSettingsUseCaseProvider)
        .execute(
          squadId: widget.squadId,
          rankingUpdate: rankingUpdate,
          rankingMultiplier: rankingMultiplier,
          useExperienceFactor: useExperienceFactor,
        );

    ref.invalidate(squadDetailProvider(widget.squadId));

    _initialRankingUpdate = rankingUpdate;
    _initialUseExperienceFactor = useExperienceFactor;
    _initialRankingMultiplier = rankingMultiplier;
    _keepTestPreviewVisibleUntilSave = false;

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  Future<void> _saveToggles({
    required bool rankingUpdate,
    required bool useExperienceFactor,
  }) async {
    final rankingMultiplier = _initialRankingMultiplier;
    if (rankingMultiplier == null) return;

    await _saveRankingSettings(
      rankingUpdate: rankingUpdate,
      useExperienceFactor: useExperienceFactor,
      rankingMultiplier: rankingMultiplier,
    );
  }

  Future<void> _onSaveMultiplierPressed() async {
    final rankingUpdate = _initialRankingUpdate;
    final useExperienceFactor = _initialUseExperienceFactor;
    final rankingMultiplier = _rankingMultiplierDraft;

    if (rankingUpdate == null ||
        useExperienceFactor == null ||
        rankingMultiplier == null) {
      return;
    }

    await _saveRankingSettings(
      rankingUpdate: rankingUpdate,
      useExperienceFactor: useExperienceFactor,
      rankingMultiplier: rankingMultiplier,
    );
  }
}

class _TestMatchPreview extends StatefulWidget {
  const _TestMatchPreview({
    required this.useExperienceFactor,
    required this.rankingMultiplier,
  });

  final bool useExperienceFactor;
  final int rankingMultiplier;

  @override
  State<_TestMatchPreview> createState() => _TestMatchPreviewState();
}

class _TestMatchPreviewState extends State<_TestMatchPreview> {
  late final TextEditingController _homeScoreController;
  late final TextEditingController _awayScoreController;

  @override
  void initState() {
    super.initState();
    _homeScoreController = TextEditingController(text: '1');
    _awayScoreController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    super.dispose();
  }

  int? _tryParseInt(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompact =
        MediaQuery.sizeOf(context).width < AppConfig.compactWidth;

    final homeScore = _tryParseInt(_homeScoreController.text);
    final awayScore = _tryParseInt(_awayScoreController.text);

    final homeMatchesPlayed = 1;
    final awayMatchesPlayed = AppConfig.maxMatchesPlayed;

    final hasValidScore = homeScore != null && awayScore != null;
    final goalDiff = hasValidScore ? (homeScore - awayScore) : null;

    final baseDelta = goalDiff == null
        ? null
        : goalDiff.toDouble() * widget.rankingMultiplier;

    final homeDelta = baseDelta == null
        ? null
        : widget.useExperienceFactor
        ? baseDelta / homeMatchesPlayed
        : baseDelta;

    final awayDelta = baseDelta == null
        ? null
        : widget.useExperienceFactor
        ? (-baseDelta) / awayMatchesPlayed
        : -baseDelta;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: _MatchScoreInputRow(
                homeController: _homeScoreController,
                awayController: _awayScoreController,
                onChanged: () => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TestPlayerCard(
                    title: widget.useExperienceFactor
                        ? 'New player'
                        : 'Equal player',
                    detailLine:
                        widget.useExperienceFactor ? '1 match' : null,
                    sideLabel: 'Home',
                    delta: homeDelta,
                    compact: isCompact,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TestPlayerCard(
                    title: widget.useExperienceFactor
                        ? 'Experienced player'
                        : 'Equal player',
                    detailLine: widget.useExperienceFactor
                        ? '${AppConfig.maxMatchesPlayed} matches'
                        : null,
                    sideLabel: 'Away',
                    delta: awayDelta,
                    compact: isCompact,
                  ),
                ),
              ],
            ),
            if (!hasValidScore) ...[
              const SizedBox(height: 8),
              SelectableText.rich(
                TextSpan(
                  text: 'Enter valid scores to preview ranking changes.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MatchScoreInputRow extends StatelessWidget {
  const _MatchScoreInputRow({
    required this.homeController,
    required this.awayController,
    required this.onChanged,
  });

  final TextEditingController homeController;
  final TextEditingController awayController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    InputDecoration decoration(String label) {
      return InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: theme.textTheme.bodySmall,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            child: TextField(
              controller: homeController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              onChanged: (_) => onChanged(),
              decoration: decoration('Home'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(':', style: theme.textTheme.titleLarge),
          ),
          SizedBox(
            width: 64,
            child: TextField(
              controller: awayController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              onChanged: (_) => onChanged(),
              decoration: decoration('Away'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestPlayerCard extends StatelessWidget {
  const _TestPlayerCard({
    required this.title,
    required this.detailLine,
    required this.sideLabel,
    required this.delta,
    required this.compact,
  });

  final String title;
  final String? detailLine;
  final String sideLabel;
  final double? delta;
  final bool compact;

  String _formatDelta(double value) {
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}';
  }

  Color _deltaColor(ThemeData theme, double value) {
    if (value > 0) {
      return theme.brightness == Brightness.dark
          ? Colors.greenAccent.shade200
          : Colors.green.shade700;
    }
    if (value < 0) return theme.colorScheme.error;
    return theme.colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final deltaText = delta == null ? '—' : _formatDelta(delta!);
    final deltaColor = delta == null
        ? colorScheme.onSurfaceVariant
        : _deltaColor(theme, delta!);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: sideLabel == 'Home'
                            ? colorScheme.primary
                            : colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (detailLine != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detailLine!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Ranking',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deltaText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: deltaColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: sideLabel == 'Home'
                            ? colorScheme.primary
                            : colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  sideLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Δ ranking',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      deltaText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: deltaColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

  static const double _actionButtonMinWidth = 200;

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
              DangerActionButton(
                label: dropdownLabel,
                minWidth: _actionButtonMinWidth,
                onPressed: onToggleExpanded,
              ),
            ],
          ),
        ),
        if (isExpanded)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DangerActionButton(
                label: optionLabel,
                minWidth: _actionButtonMinWidth,
                onPressed: onOptionPressed,
              ),
            ),
          ),
      ],
    );
  }
}
