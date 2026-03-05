import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/global_dependencies.dart';
import 'package:app/features/tournaments/domain/repositories/tournament_draft_repository.dart';
import 'package:app/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:app/features/tournaments/infrastructure/repositories/supabase_tournament_draft_repository.dart';
import 'package:app/features/tournaments/infrastructure/repositories/supabase_tournament_repository.dart';

final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SupabaseTournamentRepository(supabase);
});

final tournamentDraftRepositoryProvider = Provider<TournamentDraftRepository>((
  ref,
) {
  final supabase = ref.read(supabaseProvider);
  return SupabaseTournamentDraftRepository(supabase);
});
