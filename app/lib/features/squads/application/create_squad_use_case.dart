import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/squads/infrastructure/repositories/supabase_squad_repository.dart';

import '../domain/entities/squad.dart';
import '../domain/entities/user_squad_role.dart';
import '../domain/repositories/squad_repository.dart';

class CreateSquadResult {
  final bool success;
  final String? error;

  const CreateSquadResult.success()
      : success = true,
        error = null;

  const CreateSquadResult.failure(this.error) : success = false;
}

class CreateSquadUseCase {
  final SquadRepository _repository;

  CreateSquadUseCase(this._repository);

  Future<CreateSquadResult> execute({
    required String name,
    required SquadVisibility visibility,
    required String ownerId,
    required SportType sportType,
  }) async {
    if (name.trim().isEmpty) {
      return const CreateSquadResult.failure('Squad name cannot be empty');
    }

    final existing = await _repository.getUserSquads(ownerId);
    final ownsSquad = existing.any(
      (squad) => squad.role == SquadRole.owner && squad.ownerId == ownerId,
    );

    if (ownsSquad) {
      return const CreateSquadResult.failure(
        'You can own only one squad. Please manage your existing squad.',
      );
    }

    await _repository.createSquad(
      name.trim(),
      visibility,
      ownerId,
      sportType.name,
    );

    return const CreateSquadResult.success();
  }
}

final createSquadUseCaseProvider = Provider<CreateSquadUseCase>((ref) {
  final repository = ref.read(squadRepositoryProvider);
  return CreateSquadUseCase(repository);
});
