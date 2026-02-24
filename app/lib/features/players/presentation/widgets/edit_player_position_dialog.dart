import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/players/application/usecases/update_player_position_usecase.dart';
import 'package:app/features/players/domain/entities/player_position.dart';

class EditPlayerPositionDialog extends ConsumerStatefulWidget {
  const EditPlayerPositionDialog({
    super.key,
    required this.playerId,
    required this.initialPosition,
  });

  final String playerId;
  final String? initialPosition;

  @override
  ConsumerState<EditPlayerPositionDialog> createState() =>
      _EditPlayerPositionDialogState();
}

class _EditPlayerPositionDialogState
    extends ConsumerState<EditPlayerPositionDialog> {
  late PlayerPosition? _selectedPosition;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedPosition = playerPositionFromStorageValue(widget.initialPosition);
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref
          .read(updatePlayerPositionUseCaseProvider)
          .execute(
            playerId: widget.playerId,
            newPosition: _selectedPosition?.storageValue,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
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
    return AlertDialog(
      title: const Text('Edytuj pozycję'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<PlayerPosition?>(
            initialValue: _selectedPosition,
            decoration: const InputDecoration(
              labelText: 'Pozycja',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<PlayerPosition?>(
                value: null,
                child: Text('Brak pozycji'),
              ),
              ...PlayerPosition.values.map(
                (position) => DropdownMenuItem<PlayerPosition?>(
                  value: position,
                  child: Text(position.polishLabel),
                ),
              ),
            ],
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() {
                      _selectedPosition = value;
                    });
                  },
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            SelectableText.rich(
              TextSpan(
                text: _error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Zapisz'),
        ),
      ],
    );
  }
}
