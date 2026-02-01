import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/usecases/update_player_ranking_usecase.dart';

class EditPlayerRankingDialog extends ConsumerStatefulWidget {
  final String playerId;
  final double currentRanking;

  const EditPlayerRankingDialog({
    super.key,
    required this.playerId,
    required this.currentRanking,
  });

  @override
  ConsumerState<EditPlayerRankingDialog> createState() =>
      _EditPlayerRankingDialogState();
}

class _EditPlayerRankingDialogState
    extends ConsumerState<EditPlayerRankingDialog> {
  late double _rankingValue;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rankingValue = widget.currentRanking.clamp(0.0, 100.0).toDouble();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref
          .read(updatePlayerRankingUseCaseProvider)
          .execute(playerId: widget.playerId, newRanking: _rankingValue);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Edit Ranking'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ranking: ${_rankingValue.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium,
          ),
          Slider(
            value: _rankingValue,
            min: 0,
            max: 100,
            label: _rankingValue.toStringAsFixed(2),
            onChanged: _isLoading
                ? null
                : (value) {
                    final rounded = (value * 100).round() / 100;
                    setState(() {
                      _rankingValue = rounded;
                    });
                  },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
