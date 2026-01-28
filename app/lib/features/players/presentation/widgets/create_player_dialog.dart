import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/players/domain/entities/player.dart';
import 'package:app/features/players/presentation/controllers/players_notifier.dart';

class CreatePlayerDialog extends ConsumerStatefulWidget {
  const CreatePlayerDialog({super.key, required this.squadId});

  final String squadId;

  @override
  ConsumerState<CreatePlayerDialog> createState() => _CreatePlayerDialogState();
}

class _CreatePlayerDialogState extends ConsumerState<CreatePlayerDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _positionController;
  late final TextEditingController _baseRankingController;

  int _sliderValue = 50;
  bool _isSubmitting = false;
  bool _isUpdatingFromSlider = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _positionController = TextEditingController();
    _baseRankingController = TextEditingController(text: '50');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _baseRankingController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final position = _positionController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorText = 'Name cannot be empty.';
      });
      return;
    }

    final baseRanking = _sliderValue;

    if (baseRanking < 1 || baseRanking > 100) {
      setState(() {
        _errorText = 'Base ranking must be between 1 and 100.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    try {
      final existingPlayers = ref.read(playersNotifierProvider).value ?? [];
      final nameExists = existingPlayers.any(
        (player) => player.name.toLowerCase() == name.toLowerCase(),
      );
      if (nameExists) {
        setState(() {
          _errorText = 'Player with this name already exists.';
          _isSubmitting = false;
        });
        return;
      }

      await ref
          .read(playersNotifierProvider.notifier)
          .addPlayer(
            squadId: widget.squadId,
            name: name,
            position: position.isEmpty ? null : position,
            baseRanking: baseRanking,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      setState(() {
        _errorText = error.toString();
        _isSubmitting = false;
      });
    }
  }

  void _handleBaseRankingTextChanged(String value) {
    if (_isUpdatingFromSlider) {
      return;
    }

    final parsed = int.tryParse(value);
    if (parsed == null) {
      return;
    }

    final clamped = parsed.clamp(1, 100);
    if (clamped == _sliderValue) {
      return;
    }

    setState(() {
      _sliderValue = clamped;
    });
  }

  _NearestPlayers _findNearestPlayers(List<Player> players, int target) {
    final lowerCandidates =
        players.where((player) => player.ranking < target).toList()
          ..sort((a, b) => b.ranking.compareTo(a.ranking));
    final higherCandidates =
        players.where((player) => player.ranking > target).toList()
          ..sort((a, b) => a.ranking.compareTo(b.ranking));

    return _NearestPlayers(
      lower: lowerCandidates.isEmpty ? null : lowerCandidates.first,
      higher: higherCandidates.isEmpty ? null : higherCandidates.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final players = ref.watch(playersNotifierProvider).value ?? [];
    final nearest = _findNearestPlayers(players, _sliderValue);
    final lowerPlayer = nearest.lower;
    final higherPlayer = nearest.higher;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentWidth = (screenWidth - 48).clamp(0.0, 420.0);

    return AlertDialog(
      title: const Text('Add player'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: contentWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Position (optional)',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _baseRankingController,
                decoration: const InputDecoration(
                  labelText: 'Base ranking',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _handleBaseRankingTextChanged,
              ),
              const SizedBox(height: 8),
              Text(
                'Selected ranking: $_sliderValue',
                style: theme.textTheme.bodyMedium,
              ),
              Slider(
                value: _sliderValue.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                label: '$_sliderValue',
                onChanged: (value) {
                  final rounded = value.round();
                  setState(() {
                    _sliderValue = rounded;
                    _isUpdatingFromSlider = true;
                    _baseRankingController.text = rounded.toString();
                    _isUpdatingFromSlider = false;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _NearestPlayerProfile(
                        key: ValueKey(lowerPlayer?.playerId ?? 'lower-null'),
                        label: 'Weaker player',
                        player: lowerPlayer,
                        placeholderText: 'No weaker player',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _NearestPlayerProfile(
                        key: ValueKey(higherPlayer?.playerId ?? 'higher-null'),
                        label: 'Stronger player',
                        player: higherPlayer,
                        placeholderText: 'No stronger player',
                      ),
                    ),
                  ),
                ],
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                SelectableText.rich(
                  TextSpan(
                    text: _errorText,
                    style: const TextStyle(color: Colors.red),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}

class _NearestPlayers {
  final Player? lower;
  final Player? higher;

  const _NearestPlayers({this.lower, this.higher});
}

class _NearestPlayerProfile extends StatelessWidget {
  const _NearestPlayerProfile({
    super.key,
    required this.label,
    required this.placeholderText,
    this.player,
  });

  final String label;
  final String placeholderText;
  final Player? player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final nameFontSize = nameStyle?.fontSize ?? 14;
    final nameLineHeight = (nameStyle?.height ?? 1.2) * nameFontSize;
    final nameBoxHeight = nameLineHeight * 2;
    final bodyStyle = theme.textTheme.bodySmall;
    final bodyFontSize = bodyStyle?.fontSize ?? 12;
    final bodyLineHeight = (bodyStyle?.height ?? 1.2) * bodyFontSize;
    final cardHeight = 24 + 6 + nameBoxHeight + 2 + bodyLineHeight + 24 + 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: cardHeight,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: player == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 6),
                      Text(placeholderText, style: theme.textTheme.bodySmall),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.person, color: theme.colorScheme.primary),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: nameBoxHeight,
                        child: Text(
                          player!.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: nameStyle,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ranking: ${player!.ranking.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
