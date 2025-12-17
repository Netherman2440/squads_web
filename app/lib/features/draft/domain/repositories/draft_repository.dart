import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/players/domain/entities/player.dart';

abstract class DraftRepository {
  Future<List<Draft>> createDraft({
    required List<Player> players,
    int limit = 20,
  });
}
