import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/global_dependencies.dart';
import 'package:app/features/tournaments/application/dto/tournament_details_dto.dart';
import 'package:app/features/tournaments/application/usecases/get_tournament_usecase.dart';
import 'package:app/features/tournaments/application/usecases/get_tournaments_usecase.dart';
import 'package:app/features/tournaments/domain/entities/tournament.dart';

final squadTournamentsProvider =
    FutureProvider.family<List<Tournament>, String>((ref, squadId) {
      return ref.read(getTournamentsUseCaseProvider).execute(squadId: squadId);
    });

final tournamentDetailsProvider =
    FutureProvider.family<TournamentDetailsDto, String>((ref, tournamentId) {
      ref.watch(tournamentRealtimeTickProvider(tournamentId));
      return ref
          .read(getTournamentUseCaseProvider)
          .execute(tournamentId: tournamentId);
    });

final tournamentRealtimeTickProvider = StreamProvider.family<int, String>((
  ref,
  tournamentId,
) {
  final supabase = ref.read(supabaseProvider);
  final controller = StreamController<int>();
  var tick = 0;

  void emitTick() {
    if (controller.isClosed) {
      return;
    }
    tick += 1;
    controller.add(tick);
  }

  final filter = PostgresChangeFilter(
    type: PostgresChangeFilterType.eq,
    column: 'tournament_id',
    value: tournamentId,
  );

  final channel = supabase.channel(
    'tournament-updates-$tournamentId-${DateTime.now().microsecondsSinceEpoch}',
  );

  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'matches',
        filter: filter,
        callback: (_) => emitTick(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'tournament_teams',
        filter: filter,
        callback: (_) => emitTick(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'tournament_team_players',
        filter: filter,
        callback: (_) => emitTick(),
      )
      .subscribe();

  controller.add(tick);

  ref.onDispose(() {
    controller.close();
    supabase.removeChannel(channel);
  });

  return controller.stream;
});
