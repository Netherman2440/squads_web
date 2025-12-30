import 'package:app/features/squads/domain/entities/squad_member.dart';

import '../entities/squad.dart';

abstract class SquadRepository {
  Future<List<Squad>> getSquads({
    SquadVisibility? visibility,
    String? searchQuery,
    String? sportType,
  });

  Future<List<Squad>> getSquadsByIds(List<String> squadIds);

  Future<Squad?> getSquad(String squadId);

  Future<void> createSquad(
    String name,
    SquadVisibility visibility,
    String ownerId,
    String sportType,
  );

  Future<void> updateSquad(
    String squadId, {
    String? name,
    SquadVisibility? visibility,
    bool? rankingUpdate,
    double? rankingMultiplier,
    bool? useExperienceFactor,
  });

  Future<void> applyToSquad(String squadId, String userId);

  Future<void> addUserToSquad(String squadId, String userId);

  Future<List<SquadMember>> getSquadMembers(String squadId);
}
