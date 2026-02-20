import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/error/supabase_error_extension.dart';
import 'package:app/core/global_dependencies.dart';
import 'package:app/features/draft/domain/entities/draft.dart';
import 'package:app/features/draft/domain/entities/stored_draft_payload.dart';
import 'package:app/features/draft/domain/repositories/draft_persistence_repository.dart';

class SupabaseDraftPersistenceRepository implements DraftPersistenceRepository {
  final SupabaseClient _supabase;
  final Logger _logger = Logger('SupabaseDraftPersistenceRepository');

  SupabaseDraftPersistenceRepository(this._supabase);

  @override
  Future<void> upsertCompletedDraft({
    required String squadId,
    required String matchId,
    required List<Draft> proposals,
    required Map<String, Map<String, double>> winRateMatrix,
    required int teamCount,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final draftId = await _upsertDraftRow(
        squadId: squadId,
        matchId: matchId,
        status: 'completed',
        teamCount: teamCount,
        proposalsCount: proposals.length,
        errorMessage: null,
        updatedAt: now,
      );

      await _supabase.from('draft_payloads').upsert({
        'draft_id': draftId,
        'proposals': _serializeProposals(proposals),
        'win_rate_matrix': _serializeWinRateMatrix(winRateMatrix),
        'updated_at': now,
      }, onConflict: 'draft_id');
    } catch (e, stack) {
      _logger.severe('Failed to upsert completed draft', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<void> upsertDraftError({
    required String squadId,
    required String matchId,
    required int teamCount,
    required String errorMessage,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final draftId = await _upsertDraftRow(
        squadId: squadId,
        matchId: matchId,
        status: 'error',
        teamCount: teamCount,
        proposalsCount: 0,
        errorMessage: errorMessage,
        updatedAt: now,
      );

      await _supabase.from('draft_payloads').upsert({
        'draft_id': draftId,
        'proposals': const <Map<String, dynamic>>[],
        'win_rate_matrix': const <String, dynamic>{},
        'updated_at': now,
      }, onConflict: 'draft_id');
    } catch (e, stack) {
      _logger.severe('Failed to upsert draft error state', e, stack);
      throw e.toFailure();
    }
  }

  @override
  Future<StoredDraftPayload?> getMatchDraft({required String matchId}) async {
    try {
      final draftRow = await _supabase
          .from('drafts')
          .select(
            'draft_id, match_id, team_count, proposals_count, status, error_message',
          )
          .eq('match_id', matchId)
          .maybeSingle();

      if (draftRow == null) {
        return null;
      }

      final draftData = Map<String, dynamic>.from(draftRow as Map);
      final draftId = draftData['draft_id'] as String;

      final payloadRow = await _supabase
          .from('draft_payloads')
          .select('proposals, win_rate_matrix')
          .eq('draft_id', draftId)
          .maybeSingle();

      final payloadData = payloadRow == null
          ? const <String, dynamic>{}
          : Map<String, dynamic>.from(payloadRow as Map);

      return StoredDraftPayload(
        draftId: draftId,
        matchId: draftData['match_id'] as String,
        teamCount: (draftData['team_count'] as num?)?.toInt() ?? 2,
        proposalsCount: (draftData['proposals_count'] as num?)?.toInt() ?? 0,
        status: (draftData['status'] as String?) ?? 'completed',
        errorMessage: draftData['error_message'] as String?,
        proposals: _parseStoredProposals(payloadData['proposals']),
        winRateMatrix: _parseWinRateMatrix(payloadData['win_rate_matrix']),
      );
    } catch (e, stack) {
      _logger.severe('Failed to fetch match draft for $matchId', e, stack);
      throw e.toFailure();
    }
  }

  Future<String> _upsertDraftRow({
    required String squadId,
    required String matchId,
    required String status,
    required int teamCount,
    required int proposalsCount,
    required String? errorMessage,
    required String updatedAt,
  }) async {
    final response = await _supabase
        .from('drafts')
        .upsert({
          'squad_id': squadId,
          'match_id': matchId,
          'status': status,
          'team_count': teamCount,
          'proposals_count': proposalsCount,
          'error_message': errorMessage,
          'updated_at': updatedAt,
        }, onConflict: 'match_id')
        .select('draft_id')
        .single();

    final row = Map<String, dynamic>.from(response as Map);
    return row['draft_id'] as String;
  }
}

List<Map<String, dynamic>> _serializeProposals(List<Draft> proposals) {
  return proposals
      .map(
        (draft) => {
          'teams': draft.teams
              .map((team) => team.players.map((p) => p.playerId).toList())
              .toList(),
        },
      )
      .toList(growable: false);
}

Map<String, dynamic> _serializeWinRateMatrix(
  Map<String, Map<String, double>> matrix,
) {
  return matrix.map(
    (playerId, opponents) => MapEntry(
      playerId,
      opponents.map((oppId, rate) => MapEntry(oppId, rate)),
    ),
  );
}

List<StoredDraftProposal> _parseStoredProposals(dynamic raw) {
  if (raw is! List) {
    return const [];
  }

  final result = <StoredDraftProposal>[];

  for (final proposalRaw in raw) {
    if (proposalRaw is! Map) {
      continue;
    }

    final proposalMap = Map<String, dynamic>.from(proposalRaw);
    final teamsRaw = proposalMap['teams'];
    if (teamsRaw is! List) {
      continue;
    }

    final teams = <List<String>>[];

    for (final teamRaw in teamsRaw) {
      if (teamRaw is! List) {
        continue;
      }

      final playerIds = <String>[];
      for (final idRaw in teamRaw) {
        if (idRaw is String && idRaw.isNotEmpty) {
          playerIds.add(idRaw);
        }
      }
      teams.add(playerIds);
    }

    if (teams.isNotEmpty) {
      result.add(StoredDraftProposal(teams: teams));
    }
  }

  return result;
}

Map<String, Map<String, double>> _parseWinRateMatrix(dynamic raw) {
  if (raw is! Map) {
    return const {};
  }

  final matrix = <String, Map<String, double>>{};

  for (final entry in raw.entries) {
    final playerId = entry.key;
    final value = entry.value;

    if (playerId is! String || value is! Map) {
      continue;
    }

    final opponents = <String, double>{};

    for (final oppEntry in value.entries) {
      final oppId = oppEntry.key;
      final rate = oppEntry.value;

      if (oppId is! String || rate is! num) {
        continue;
      }

      opponents[oppId] = rate.toDouble();
    }

    matrix[playerId] = opponents;
  }

  return matrix;
}

final draftPersistenceRepositoryProvider = Provider<DraftPersistenceRepository>(
  (ref) {
    final supabase = ref.read(supabaseProvider);
    return SupabaseDraftPersistenceRepository(supabase);
  },
);
