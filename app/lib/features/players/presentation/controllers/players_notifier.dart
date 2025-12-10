import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../squads/domain/entities/user_squad_role.dart';
import '../../application/usecases/add_player_usecase.dart';
import '../../application/usecases/delete_player_usecase.dart';
import '../../application/usecases/get_squad_players_usecase.dart';
import '../../domain/entities/player.dart';

class PlayersState {
  const PlayersState({
    this.players = const [],
    this.searchQuery = '',
    this.sortOption = PlayersSortOption.name,
  });

  final List<Player> players;
  final String searchQuery;
  final PlayersSortOption sortOption;

  List<Player> get filteredPlayers {
    final query = searchQuery.toLowerCase().trim();

    final filtered = players.where((player) {
      if (query.isEmpty) return true;
      return player.name.toLowerCase().contains(query) ||
          (player.position?.toLowerCase().contains(query) ?? false);
    });

    final sorted = [...filtered];
    sorted.sort((a, b) {
      switch (sortOption) {
        case PlayersSortOption.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case PlayersSortOption.position:
          return (a.position ?? '').toLowerCase().compareTo(
                (b.position ?? '').toLowerCase(),
              );
        case PlayersSortOption.score:
          return b.score.compareTo(a.score);
        case PlayersSortOption.baseScore:
          return b.baseScore.compareTo(a.baseScore);
      }
    });

    return sorted;
  }

  PlayersState copyWith({
    List<Player>? players,
    String? searchQuery,
    PlayersSortOption? sortOption,
  }) {
    return PlayersState(
      players: players ?? this.players,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

enum PlayersSortOption { name, position, score, baseScore }

extension PlayersSortOptionLabel on PlayersSortOption {
  String get label {
    switch (this) {
      case PlayersSortOption.name:
        return 'Name';
      case PlayersSortOption.position:
        return 'Position';
      case PlayersSortOption.score:
        return 'Score';
      case PlayersSortOption.baseScore:
        return 'Base score';
    }
  }
}

class PlayersNotifier
    extends AutoDisposeAsyncNotifier<PlayersState> {
  String? _squadId;

  @override
  Future<PlayersState> build(String squadId) async {
    _squadId = squadId;
    return _fetchPlayers(current: const PlayersState());
  }

  Future<void> refreshPlayers() async {
    final previous = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPlayers(current: previous));
  }

  Future<void> addPlayer({
    required String name,
    String? position,
    required int baseScore,
  }) async {
    final previous = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(addPlayerUseCaseProvider).execute(
            squadId: _ensureSquadId(),
            name: name,
            position: position,
            baseScore: baseScore,
          );

      return _fetchPlayers(current: previous);
    });
  }

  Future<void> deletePlayer(String playerId) async {
    final previous = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(deletePlayerUseCaseProvider).execute(
            playerId: playerId,
          );
      return _fetchPlayers(current: previous);
    });
  }

  void updateSearchQuery(String query) {
    final current = state.valueOrNull ?? const PlayersState();
    state = AsyncValue.data(current.copyWith(searchQuery: query));
  }

  void updateSortOption(PlayersSortOption option) {
    final current = state.valueOrNull ?? const PlayersState();
    state = AsyncValue.data(current.copyWith(sortOption: option));
  }

  bool canManagePlayers(UserSquadRole role) {
    return role == UserSquadRole.owner || role == UserSquadRole.admin;
  }

  Future<PlayersState> _fetchPlayers({PlayersState? current}) async {
    final players = await ref
        .read(getSquadPlayersUseCaseProvider)
        .execute(squadId: _ensureSquadId());

    final baseState = current ?? state.valueOrNull ?? const PlayersState();
    return baseState.copyWith(players: players);
  }

  String _ensureSquadId() {
    final squadId = _squadId;
    if (squadId == null) {
      throw StateError('Squad ID is not set for PlayersNotifier');
    }
    return squadId;
  }
}

final playersNotifierProvider = AutoDisposeAsyncNotifierProviderFamily<
    PlayersNotifier, PlayersState, String>(PlayersNotifier.new);
