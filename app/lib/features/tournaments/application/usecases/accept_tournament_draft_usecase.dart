import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/error/failure.dart';
import 'package:app/features/tournaments/domain/entities/tournament_status.dart';
import 'package:app/features/tournaments/domain/entities/tournament_team.dart';
import 'package:app/features/tournaments/domain/repositories/tournament_draft_repository.dart';
import 'package:app/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:app/features/tournaments/tournaments_providers.dart';

class AcceptTournamentDraftUseCase {
  final TournamentRepository _tournamentRepository;
  final TournamentDraftRepository _tournamentDraftRepository;

  const AcceptTournamentDraftUseCase(
    this._tournamentRepository,
    this._tournamentDraftRepository,
  );

  Future<void> execute({
    required String tournamentId,
    required String tournamentDraftId,
    required int proposalIndex,
  }) async {
    final draft = await _tournamentDraftRepository.getTournamentDraft(
      tournamentDraftId: tournamentDraftId,
    );

    if (draft == null) {
      throw const NotFoundFailure('Tournament draft not found.');
    }
    if (draft.tournamentId != tournamentId) {
      throw const ValidationFailure('Draft does not belong to this tournament.');
    }
    if (draft.status == 'error') {
      throw ValidationFailure(draft.errorMessage ?? 'Cannot accept failed draft.');
    }
    if (proposalIndex < 0 || proposalIndex >= draft.proposals.length) {
      throw const ValidationFailure('Invalid proposal index.');
    }

    final proposal = draft.proposals[proposalIndex];
    final flattenedPlayerIds = proposal.teams
        .expand((team) => team)
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final uniquePlayers = flattenedPlayerIds.toSet();
    if (uniquePlayers.length != flattenedPlayerIds.length) {
      throw const ValidationFailure(
        'Each selected player must be assigned to exactly one team.',
      );
    }

    final expectedPlayers = draft.selectedPlayerIds.toSet();
    if (expectedPlayers.isNotEmpty) {
      if (uniquePlayers.length != expectedPlayers.length ||
          !uniquePlayers.containsAll(expectedPlayers)) {
        throw const ValidationFailure(
          'Draft proposal does not contain full tournament roster.',
        );
      }
    }

    final existingTeams = await _tournamentRepository.getTournamentTeams(
      tournamentId: tournamentId,
    );

    final teamInputs = <TournamentTeamInput>[];
    for (var index = 0; index < proposal.teams.length; index++) {
      final existing = index < existingTeams.length ? existingTeams[index] : null;
      final playerIds = proposal.teams[index].toSet().toList(growable: false);

      teamInputs.add(
        TournamentTeamInput(
          tournamentTeamId: existing?.tournamentTeamId,
          name: _resolvedTeamName(existing, index),
          color: _resolvedTeamColor(existing, index),
          playerIds: playerIds,
        ),
      );
    }

    await _tournamentRepository.replaceTournamentTeams(
      tournamentId: tournamentId,
      teams: teamInputs,
    );

    await _tournamentRepository.updateTournament(
      tournamentId: tournamentId,
      status: TournamentStatus.active,
      acceptedTournamentDraftId: tournamentDraftId,
    );
  }
}

String _resolvedTeamName(TournamentTeam? existing, int index) {
  final value = existing?.name?.trim();
  if (value == null || value.isEmpty) {
    return 'Team ${index + 1}';
  }
  return value;
}

String _resolvedTeamColor(TournamentTeam? existing, int index) {
  final value = existing?.color?.trim();
  if (value != null && value.isNotEmpty) {
    return value;
  }

  return _defaultTeamColors[index % _defaultTeamColors.length];
}

const List<String> _defaultTeamColors = [
  '#E53935',
  '#1E88E5',
  '#43A047',
  '#FB8C00',
];

final acceptTournamentDraftUseCaseProvider =
    Provider<AcceptTournamentDraftUseCase>((ref) {
      return AcceptTournamentDraftUseCase(
        ref.read(tournamentRepositoryProvider),
        ref.read(tournamentDraftRepositoryProvider),
      );
    });
