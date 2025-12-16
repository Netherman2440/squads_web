enum MatchScoreType {
  regular,
  overtime,
  penalties,
}

extension MatchScoreTypeExtension on MatchScoreType {
  static MatchScoreType? fromString(String? value) {
    if (value == null) {
      return null;
    }

    try {
      return MatchScoreType.values.firstWhere(
        (type) => type.name == value,
      );
    } catch (_) {
      return null;
    }
  }

  String get label {
    switch (this) {
      case MatchScoreType.regular:
        return 'Regular time';
      case MatchScoreType.overtime:
        return 'Overtime';
      case MatchScoreType.penalties:
        return 'Penalties';
    }
  }
}
