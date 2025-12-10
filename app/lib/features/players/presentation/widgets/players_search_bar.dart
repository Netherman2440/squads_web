import 'package:flutter/material.dart';

class PlayersSearchBar extends StatefulWidget {
  const PlayersSearchBar({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<PlayersSearchBar> createState() => _PlayersSearchBarState();
}

class _PlayersSearchBarState extends State<PlayersSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant PlayersSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          labelText: 'Search players',
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
