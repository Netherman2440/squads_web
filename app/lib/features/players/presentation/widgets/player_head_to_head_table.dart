import 'package:flutter/material.dart';

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

class PlayerHeadToHeadTable extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const Text('No head-to-head stats yet.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final highlightColor = Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.22);

        final columns = _orderedColumns();
        final sorted = [...stats]..sort(
            (a, b) =>
                _compare(a, b, column: sortColumn, ascending: sortAscending),
          );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: 16,
              sortAscending: sortAscending,
              sortColumnIndex: columns.indexOf(sortColumn),
              columns: columns
                  .map(
                    (column) => DataColumn(
                      label: _cellWrapper(
                        column,
                        _columnLabel(column, isWide: isWide),
                        highlightColor,
                      ),
                      onSort: (_, _) => _handleSort(column),
                    ),
                  )
                  .toList(growable: false),
              rows: sorted
                  .map(
                    (stat) => DataRow(
                      cells: [
                        DataCell(
                          _cellWrapper(
                            HeadToHeadColumn.player,
                            Text(stat.otherName),
                            highlightColor,
                          ),
                        ),
                        DataCell(
                          _cellWrapper(
                            HeadToHeadColumn.togetherMatches,
                            Text(stat.togetherMatches.toString()),
                            highlightColor,
                          ),
                        ),
                        DataCell(
                          _cellWrapper(
                            HeadToHeadColumn.togetherWins,
                            Text(stat.togetherWins.toString()),
                            highlightColor,
                          ),
                        ),
                        DataCell(
                          _cellWrapper(
                            HeadToHeadColumn.togetherDraws,
                            Text(stat.togetherDraws.toString()),
                            highlightColor,
                          ),
                        ),
                        DataCell(
                          _cellWrapper(
                            HeadToHeadColumn.togetherLosses,
                            Text(stat.togetherLosses.toString()),
                            highlightColor,
                          ),
                        ),
                        DataCell(
                          _cellWrapper(
                            HeadToHeadColumn.togetherGoalsFor,
                            Text(stat.togetherGoalsFor.toString()),
                            highlightColor,
                          ),
                        ),
                        DataCell(
                          _cellWrapper(
                            HeadToHeadColumn.togetherGoalsAgainst,
                            Text(stat.togetherGoalsAgainst.toString()),
                            highlightColor,
                          ),
                        ),
                        DataCell(
                          _cellWrapper(
                            HeadToHeadColumn.vsMatches,
                            Text(stat.vsMatches.toString()),
                            highlightColor,
                          ),
                        ),
                        DataCell(
                          _cellWrapper(
                            HeadToHeadColumn.vsWins,
                            Text(stat.vsWins.toString()),
                            highlightColor,
                          ),
                        ),
                        DataCell(
                          _cellWrapper(
                            HeadToHeadColumn.vsDraws,
                            Text(stat.vsDraws.toString()),
                            highlightColor,
                          ),
                        ),
                        DataCell(
                          _cellWrapper(
                            HeadToHeadColumn.vsLosses,
                            Text(stat.vsLosses.toString()),
                            highlightColor,
                          ),
                        ),
                        DataCell(
                          _cellWrapper(
                            HeadToHeadColumn.vsGoalsFor,
                            Text(stat.vsGoalsFor.toString()),
                            highlightColor,
                          ),
                        ),
                        DataCell(
                          _cellWrapper(
                            HeadToHeadColumn.vsGoalsAgainst,
                            Text(stat.vsGoalsAgainst.toString()),
                            highlightColor,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        );
      },
    );
  }

  void _handleSort(HeadToHeadColumn column) {
    if (column == sortColumn) {
      onSort(column, !sortAscending);
    } else {
      onSort(column, false);
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

  Widget _columnLabel(HeadToHeadColumn column, {required bool isWide}) {
    switch (column) {
      case HeadToHeadColumn.player:
        return const Text('Gracz');
      case HeadToHeadColumn.togetherMatches:
        return _label(short: 'R M', full: 'Razem mecze', isWide: isWide);
      case HeadToHeadColumn.togetherWins:
        return _label(short: 'R W', full: 'Razem wygrane', isWide: isWide);
      case HeadToHeadColumn.togetherDraws:
        return _label(short: 'R D', full: 'Razem remisy', isWide: isWide);
      case HeadToHeadColumn.togetherLosses:
        return _label(short: 'R L', full: 'Razem porażki', isWide: isWide);
      case HeadToHeadColumn.togetherGoalsFor:
        return _label(
          short: 'R GS',
          full: 'Razem gole strzelone',
          isWide: isWide,
        );
      case HeadToHeadColumn.togetherGoalsAgainst:
        return _label(
          short: 'R GA',
          full: 'Razem gole stracone',
          isWide: isWide,
        );
      case HeadToHeadColumn.vsMatches:
        return _label(short: 'VS M', full: 'Przeciwko mecze', isWide: isWide);
      case HeadToHeadColumn.vsWins:
        return _label(short: 'VS W', full: 'Przeciwko wygrane', isWide: isWide);
      case HeadToHeadColumn.vsDraws:
        return _label(short: 'VS D', full: 'Przeciwko remisy', isWide: isWide);
      case HeadToHeadColumn.vsLosses:
        return _label(short: 'VS L', full: 'Przeciwko porażki', isWide: isWide);
      case HeadToHeadColumn.vsGoalsFor:
        return _label(
          short: 'VS GS',
          full: 'Przeciwko gole strzelone',
          isWide: isWide,
        );
      case HeadToHeadColumn.vsGoalsAgainst:
        return _label(
          short: 'VS GA',
          full: 'Przeciwko gole stracone',
          isWide: isWide,
        );
    }
  }

  Widget _label({
    required String short,
    required String full,
    required bool isWide,
  }) {
    if (isWide) {
      return Text(full);
    }
    return Tooltip(message: full, child: Text(short));
  }

  Widget _cellWrapper(
    HeadToHeadColumn column,
    Widget child,
    Color highlightColor,
  ) {
    final isSelected = column == sortColumn;
    return Container(
      color: isSelected ? highlightColor : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: child,
    );
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
