import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/players/presentation/controllers/players_notifier.dart';

class CreatePlayerDialog extends ConsumerStatefulWidget {
  const CreatePlayerDialog({
    super.key,
    required this.squadId,
  });

  final String squadId;

  @override
  ConsumerState<CreatePlayerDialog> createState() =>
      _CreatePlayerDialogState();
}

class _CreatePlayerDialogState extends ConsumerState<CreatePlayerDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _positionController;
  late final TextEditingController _baseScoreController;

  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _positionController = TextEditingController();
    _baseScoreController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _baseScoreController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final position = _positionController.text.trim();
    final baseScoreText = _baseScoreController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorText = 'Name cannot be empty.';
      });
      return;
    }

    final baseScore = int.tryParse(baseScoreText);
    if (baseScore == null) {
      setState(() {
        _errorText = 'Base score must be an integer.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    try {
      await ref.read(playersNotifierProvider.notifier).addPlayer(
            squadId: widget.squadId,
            name: name,
            position: position.isEmpty ? null : position,
            baseScore: baseScore,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add player'),
      content: SingleChildScrollView(
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
              controller: _baseScoreController,
              decoration: const InputDecoration(
                labelText: 'Base score',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
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


