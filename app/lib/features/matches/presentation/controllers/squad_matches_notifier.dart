import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/matches/application/usecases/get_squad_matches_usecase.dart';
import 'package:app/features/matches/domain/entities/match.dart';

part 'squad_matches_notifier.g.dart';

@riverpod
class SquadMatchesNotifier extends _$SquadMatchesNotifier {
  @override
  AsyncValue<List<Match>> build(String squadId) {
    // Initial load
    _loadMatches();
    return const AsyncValue.loading();
  }

  Future<void> _loadMatches() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref.read(getSquadMatchesUseCaseProvider).execute(squadId: squadId);
    });
  }

  Future<void> refresh() async {
    await _loadMatches();
  }
}

