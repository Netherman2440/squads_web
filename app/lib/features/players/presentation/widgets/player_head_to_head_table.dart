import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:app/core/app_config.dart';
import 'package:app/features/players/domain/entities/player_head_to_head_stat.dart';

enum HeadToHeadColumn {
  player,
  togetherMatches,
  togetherWins,
  togetherDraws,
  togetherLosses,
  togetherGoalsFor,
  togetherGoalsAgainst,
  vsMatches,
  vsWins,
  vsDraws,
  vsLosses,
  vsGoalsFor,
  vsGoalsAgainst,
}

class PlayerHeadToHeadTable extends StatefulWidget {
  const PlayerHeadToHeadTable({
    super.key,
    required this.stats,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
  });

  final List<PlayerHeadToHeadStat> stats;
  final HeadToHeadColumn sortColumn;
  final bool sortAscending;
  final void Function(HeadToHeadColumn column, bool ascending) onSort;

  @override
  State<PlayerHeadToHeadTable> createState() => _PlayerHeadToHeadTableState();
}

class _PlayerHeadToHeadTableState extends State<PlayerHeadToHeadTable> {
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();
  final ScrollController _leftVerticalController = ScrollController();
  final ScrollController _bodyVerticalController = ScrollController();

  bool _isSyncingHorizontal = false;
  bool _isSyncingVertical = false;

  @override
  void initState() {
    super.initState();
    _headerHorizontalController.addListener(
      () => _syncHorizontal(
        _headerHorizontalController,
        _bodyHorizontalController,
      ),
    );
    _bodyHorizontalController.addListener(
      () => _syncHorizontal(
        _bodyHorizontalController,
        _headerHorizontalController,
      ),
    );
    _leftVerticalController.addListener(
      () => _syncVertical(_leftVerticalController, _bodyVerticalController),
    );
    _bodyVerticalController.addListener(
      () => _syncVertical(_bodyVerticalController, _leftVerticalController),
    );
  }

  @override
  void dispose() {
    _headerHorizontalController.dispose();
    _bodyHorizontalController.dispose();
    _leftVerticalController.dispose();
    _bodyVerticalController.dispose();
    super.dispose();
  }

  void _syncHorizontal(ScrollController source, ScrollController target) {
    if (_isSyncingHorizontal || !source.hasClients || !target.hasClients) {
      return;
    }

    _isSyncingHorizontal = true;
    final max = target.position.maxScrollExtent;
    final next = source.offset.clamp(0.0, max);
    if ((target.offset - next).abs() > 0.5) {
      target.jumpTo(next);
    }
    _isSyncingHorizontal = false;
  }

  void _syncVertical(ScrollController source, ScrollController target) {
    if (_isSyncingVertical || !source.hasClients || !target.hasClients) {
      return;
    }

    _isSyncingVertical = true;
    final max = target.position.maxScrollExtent;
    final next = source.offset.clamp(0.0, max);
    if ((target.offset - next).abs() > 0.5) {
      target.jumpTo(next);
    }
    _isSyncingVertical = false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stats.isEmpty) {
      return const Text('No head-to-head stats yet.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final highlightColor = theme.colorScheme.primary.withValues(
          alpha: 0.22,
        );
        final isCompact = constraints.maxWidth < AppConfig.compactWidth;
        final rowHeight = isCompact ? 44.0 : 48.0;
        final playerColumnWidth = isCompact ? 140.0 : 180.0;
        final statColumnWidth = isCompact ? 120.0 : 140.0;
        final columns = _orderedColumns();
        final statColumns = columns
            .where((column) => column != HeadToHeadColumn.player)
            .toList(growable: false);

        final sorted = [...widget.stats]
          ..sort(
            (a, b) => _compare(
              a,
              b,
              column: widget.sortColumn,
              ascending: widget.sortAscending,
            ),
          );

        final tableHeight = _tableHeight(
          context,
          rowHeight: rowHeight,
          rowCount: sorted.length,
        );

        return SizedBox(
          height: tableHeight,
          child: Column(
            children: [
              SizedBox(
                height: rowHeight,
                child: Row(
                  children: [
                    _HeaderCell(
                      width: playerColumnWidth,
                      label: _columnLabel(HeadToHeadColumn.player),
                      isSelected: widget.sortColumn == HeadToHeadColumn.player,
                      isAscending: widget.sortAscending,
                      highlightColor: highlightColor,
                      onTap: () => _handleSort(HeadToHeadColumn.player),
                    ),
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: const _TableScrollBehavior(),
                        child: SingleChildScrollView(
                          controller: _headerHorizontalController,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final column in statColumns)
                                _HeaderCell(
                                  width: statColumnWidth,
                                  label: _columnLabel(column),
                                  isSelected: widget.sortColumn == column,
                                  isAscending: widget.sortAscending,
                                  highlightColor: highlightColor,
                                  onTap: () => _handleSort(column),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: playerColumnWidth,
                      child: ScrollConfiguration(
                        behavior: const _TableScrollBehavior(),
                        child: ListView.builder(
                          controller: _leftVerticalController,
                          itemExtent: rowHeight,
                          itemCount: sorted.length,
                          itemBuilder: (context, index) {
                            final stat = sorted[index];
                            return _BodyCell(
                              width: playerColumnWidth,
                              value: stat.otherName,
                              isSelected:
                                  widget.sortColumn == HeadToHeadColumn.player,
                              highlightColor: highlightColor,
                              alignStart: true,
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        controller: _bodyHorizontalController,
                        thumbVisibility: true,
                        child: ScrollConfiguration(
                          behavior: const _TableScrollBehavior(),
                          child: SingleChildScrollView(
                            controller: _bodyHorizontalController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: statColumns.length * statColumnWidth,
                              child: Scrollbar(
                                controller: _bodyVerticalController,
                                thumbVisibility: true,
                                child: ScrollConfiguration(
                                  behavior: const _TableScrollBehavior(),
                                  child: ListView.builder(
                                    controller: _bodyVerticalController,
                                    itemExtent: rowHeight,
                                    itemCount: sorted.length,
                                    itemBuilder: (context, index) {
                                      final stat = sorted[index];
                                      return Row(
                                        children: [
                                          for (final column in statColumns)
                                            _BodyCell(
                                              width: statColumnWidth,
                                              value: _valueFor(stat, column),
                                              isSelected:
                                                  widget.sortColumn == column,
                                              highlightColor: highlightColor,
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _tableHeight(
    BuildContext context, {
    required double rowHeight,
    required int rowCount,
  }) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxHeight = screenHeight * 0.6;
    const minHeight = 240.0;
    final upperBound = maxHeight < minHeight ? minHeight : maxHeight;
    final target = rowHeight * (rowCount + 1) + 12;
    final clamped = target.clamp(minHeight, upperBound);
    return (clamped as num).toDouble();
  }

  void _handleSort(HeadToHeadColumn column) {
    if (column == widget.sortColumn) {
      widget.onSort(column, !widget.sortAscending);
    } else {
      widget.onSort(column, false);
    }
  }

  List<HeadToHeadColumn> _orderedColumns() {
    return const [
      HeadToHeadColumn.player,
      HeadToHeadColumn.togetherMatches,
      HeadToHeadColumn.togetherWins,
      HeadToHeadColumn.togetherDraws,
      HeadToHeadColumn.togetherLosses,
      HeadToHeadColumn.togetherGoalsFor,
      HeadToHeadColumn.togetherGoalsAgainst,
      HeadToHeadColumn.vsMatches,
      HeadToHeadColumn.vsWins,
      HeadToHeadColumn.vsDraws,
      HeadToHeadColumn.vsLosses,
      HeadToHeadColumn.vsGoalsFor,
      HeadToHeadColumn.vsGoalsAgainst,
    ];
  }

  String _columnLabel(HeadToHeadColumn column) {
    switch (column) {
      case HeadToHeadColumn.player:
        return 'Gracz';
      case HeadToHeadColumn.togetherMatches:
        return 'Razem mecze';
      case HeadToHeadColumn.togetherWins:
        return 'Razem wygrane';
      case HeadToHeadColumn.togetherDraws:
        return 'Razem remisy';
      case HeadToHeadColumn.togetherLosses:
        return 'Razem porażki';
      case HeadToHeadColumn.togetherGoalsFor:
        return 'Razem gole strzelone';
      case HeadToHeadColumn.togetherGoalsAgainst:
        return 'Razem gole stracone';
      case HeadToHeadColumn.vsMatches:
        return 'Przeciwko mecze';
      case HeadToHeadColumn.vsWins:
        return 'Przeciwko wygrane';
      case HeadToHeadColumn.vsDraws:
        return 'Przeciwko remisy';
      case HeadToHeadColumn.vsLosses:
        return 'Przeciwko porażki';
      case HeadToHeadColumn.vsGoalsFor:
        return 'Przeciwko gole strzelone';
      case HeadToHeadColumn.vsGoalsAgainst:
        return 'Przeciwko gole stracone';
    }
  }

  String _valueFor(PlayerHeadToHeadStat stat, HeadToHeadColumn column) {
    switch (column) {
      case HeadToHeadColumn.togetherMatches:
        return stat.togetherMatches.toString();
      case HeadToHeadColumn.togetherWins:
        return stat.togetherWins.toString();
      case HeadToHeadColumn.togetherDraws:
        return stat.togetherDraws.toString();
      case HeadToHeadColumn.togetherLosses:
        return stat.togetherLosses.toString();
      case HeadToHeadColumn.togetherGoalsFor:
        return stat.togetherGoalsFor.toString();
      case HeadToHeadColumn.togetherGoalsAgainst:
        return stat.togetherGoalsAgainst.toString();
      case HeadToHeadColumn.vsMatches:
        return stat.vsMatches.toString();
      case HeadToHeadColumn.vsWins:
        return stat.vsWins.toString();
      case HeadToHeadColumn.vsDraws:
        return stat.vsDraws.toString();
      case HeadToHeadColumn.vsLosses:
        return stat.vsLosses.toString();
      case HeadToHeadColumn.vsGoalsFor:
        return stat.vsGoalsFor.toString();
      case HeadToHeadColumn.vsGoalsAgainst:
        return stat.vsGoalsAgainst.toString();
      case HeadToHeadColumn.player:
        return stat.otherName;
    }
  }

  int _compare(
    PlayerHeadToHeadStat a,
    PlayerHeadToHeadStat b, {
    required HeadToHeadColumn column,
    required bool ascending,
  }) {
    int compareNum(num left, num right) {
      return ascending ? left.compareTo(right) : right.compareTo(left);
    }

    int compareString(String left, String right) {
      return ascending ? left.compareTo(right) : right.compareTo(left);
    }

    int result;
    switch (column) {
      case HeadToHeadColumn.player:
        result = compareString(a.otherName, b.otherName);
        break;
      case HeadToHeadColumn.togetherMatches:
        result = compareNum(a.togetherMatches, b.togetherMatches);
        break;
      case HeadToHeadColumn.togetherWins:
        result = compareNum(a.togetherWins, b.togetherWins);
        break;
      case HeadToHeadColumn.togetherDraws:
        result = compareNum(a.togetherDraws, b.togetherDraws);
        break;
      case HeadToHeadColumn.togetherLosses:
        result = compareNum(a.togetherLosses, b.togetherLosses);
        break;
      case HeadToHeadColumn.togetherGoalsFor:
        result = compareNum(a.togetherGoalsFor, b.togetherGoalsFor);
        break;
      case HeadToHeadColumn.togetherGoalsAgainst:
        result = compareNum(a.togetherGoalsAgainst, b.togetherGoalsAgainst);
        break;
      case HeadToHeadColumn.vsMatches:
        result = compareNum(a.vsMatches, b.vsMatches);
        break;
      case HeadToHeadColumn.vsWins:
        result = compareNum(a.vsWins, b.vsWins);
        break;
      case HeadToHeadColumn.vsDraws:
        result = compareNum(a.vsDraws, b.vsDraws);
        break;
      case HeadToHeadColumn.vsLosses:
        result = compareNum(a.vsLosses, b.vsLosses);
        break;
      case HeadToHeadColumn.vsGoalsFor:
        result = compareNum(a.vsGoalsFor, b.vsGoalsFor);
        break;
      case HeadToHeadColumn.vsGoalsAgainst:
        result = compareNum(a.vsGoalsAgainst, b.vsGoalsAgainst);
        break;
    }

    if (result != 0) {
      return result;
    }

    if (_isTogetherColumn(column) &&
        column != HeadToHeadColumn.togetherMatches) {
      result = compareNum(a.togetherMatches, b.togetherMatches);
    } else if (_isVsColumn(column) && column != HeadToHeadColumn.vsMatches) {
      result = compareNum(a.vsMatches, b.vsMatches);
    }

    if (result != 0) {
      return result;
    }

    return compareString(a.otherName, b.otherName);
  }

  bool _isTogetherColumn(HeadToHeadColumn column) {
    return column == HeadToHeadColumn.togetherMatches ||
        column == HeadToHeadColumn.togetherWins ||
        column == HeadToHeadColumn.togetherDraws ||
        column == HeadToHeadColumn.togetherLosses ||
        column == HeadToHeadColumn.togetherGoalsFor ||
        column == HeadToHeadColumn.togetherGoalsAgainst;
  }

  bool _isVsColumn(HeadToHeadColumn column) {
    return column == HeadToHeadColumn.vsMatches ||
        column == HeadToHeadColumn.vsWins ||
        column == HeadToHeadColumn.vsDraws ||
        column == HeadToHeadColumn.vsLosses ||
        column == HeadToHeadColumn.vsGoalsFor ||
        column == HeadToHeadColumn.vsGoalsAgainst;
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.width,
    required this.label,
    required this.isSelected,
    required this.isAscending,
    required this.highlightColor,
    required this.onTap,
  });

  final double width;
  final String label;
  final bool isSelected;
  final bool isAscending;
  final Color highlightColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = isSelected
        ? Icon(
            isAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            size: 18,
          )
        : null;
    final iconWidgets = icon == null ? null : <Widget>[icon];

    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: isSelected ? highlightColor : Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...?iconWidgets,
          ],
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell({
    required this.width,
    required this.value,
    required this.isSelected,
    required this.highlightColor,
    this.alignStart = false,
  });

  final double width;
  final String value;
  final bool isSelected;
  final Color highlightColor;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: alignStart ? Alignment.centerLeft : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isSelected ? highlightColor : Colors.transparent,
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alignStart ? TextAlign.left : TextAlign.center,
      ),
    );
  }
}

class _TableScrollBehavior extends MaterialScrollBehavior {
  const _TableScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
