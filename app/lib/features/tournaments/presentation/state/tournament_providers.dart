import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      return ref
          .read(getTournamentUseCaseProvider)
          .execute(tournamentId: tournamentId);
    });
