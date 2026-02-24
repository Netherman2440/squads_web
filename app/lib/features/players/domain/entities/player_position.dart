enum PlayerPosition { goalkeeper, defender, midfielder, attacker }

extension PlayerPositionX on PlayerPosition {
  String get storageValue {
    return switch (this) {
      PlayerPosition.goalkeeper => 'goalkeeper',
      PlayerPosition.defender => 'defender',
      // Keep DB compatibility with existing plan spelling.
      PlayerPosition.midfielder => 'middlefielder',
      PlayerPosition.attacker => 'attacker',
    };
  }

  String get polishLabel {
    return switch (this) {
      PlayerPosition.goalkeeper => 'Bramkarz',
      PlayerPosition.defender => 'Obrońca',
      PlayerPosition.midfielder => 'Pomocnik',
      PlayerPosition.attacker => 'Napastnik',
    };
  }
}

PlayerPosition? playerPositionFromStorageValue(String? value) {
  final normalized = value?.trim().toLowerCase();
  return switch (normalized) {
    null || '' || 'none' => null,
    'goalkeeper' => PlayerPosition.goalkeeper,
    'defender' => PlayerPosition.defender,
    'middlefielder' || 'midfielder' => PlayerPosition.midfielder,
    'attacker' => PlayerPosition.attacker,
    _ => null,
  };
}

String? normalizePlayerPositionStorageValue(String? value) {
  final position = playerPositionFromStorageValue(value);
  return position?.storageValue;
}

String? playerPositionPolishLabel(String? value) {
  final normalized = value?.trim();
  if (normalized == null ||
      normalized.isEmpty ||
      normalized.toLowerCase() == 'none') {
    return null;
  }

  final parsed = playerPositionFromStorageValue(normalized);
  if (parsed != null) {
    return parsed.polishLabel;
  }

  return normalized;
}
