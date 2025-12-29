import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/matches/domain/repositories/match_repository.dart';
import 'package:app/features/matches/domain/repositories/team_repository.dart';
import 'package:app/core/global_dependencies.dart';
import 'supabase_match_repository.dart';
import 'supabase_team_repository.dart';

/// Provider that binds SupabaseMatchRepository to MatchRepository interface
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SupabaseMatchRepository(supabase);
});

/// Provider that binds SupabaseTeamRepository to TeamRepository interface
final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SupabaseTeamRepository(supabase);
});
