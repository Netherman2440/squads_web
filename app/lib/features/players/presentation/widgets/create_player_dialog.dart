import 'package:flutter/material.dart';

class CreatePlayerResult {
  const CreatePlayerResult({
    required this.name,
    this.position,
    required this.baseScore,
  });

  final String name;
  final String? position;
  final int baseScore;
}

class CreatePlayerDialog extends StatefulWidget {
  const CreatePlayerDialog({super.key});

  @override
  State<CreatePlayerDialog> createState() => _CreatePlayerDialogState();
}

class _CreatePlayerDialogState extends State<CreatePlayerDialog> {
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _baseScoreController = TextEditingController();

  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _baseScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add player'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter player name',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _positionController,
            decoration: const InputDecoration(
              labelText: 'Position (optional)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _baseScoreController,
            decoration: const InputDecoration(
              labelText: 'Base score',
              hintText: '0',
            ),
            keyboardType: TextInputType.number,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final baseScoreText = _baseScoreController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Name cannot be empty.';
      });
      return;
    }

    final baseScore = int.tryParse(baseScoreText);
    if (baseScore == null) {
      setState(() {
        _errorMessage = 'Base score must be a valid number.';
      });
      return;
    }

    Navigator.of(context).pop(
      CreatePlayerResult(
        name: name,
        position: _positionController.text.trim().isEmpty
            ? null
            : _positionController.text.trim(),
        baseScore: baseScore,
      ),
    );
  }
}
