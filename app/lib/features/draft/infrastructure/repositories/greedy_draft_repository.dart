import 'package:app/features/draft/domain/repositories/draft_repository.dart';
import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/players/domain/entities/player.dart';

class GreedyDraftRepository implements DraftRepository {
  const GreedyDraftRepository();

  @override
  Future<List<Draft>> createDraft({
    required List<Player> players,
    int limit = 20,
    bool playWithSubstitute = true,
  }) async {
    return [];
  }
}