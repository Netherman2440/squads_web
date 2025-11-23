import '../entities/squad.dart';

abstract class SquadRepository {
  Future<List<Squad>> getSquads({
    SquadVisibility? visibility,
    String? searchQuery,
    String? sportType,
  });

  Future<List<Squad>> getUserSquads(String userId);

  Future<void> createSquad(
    String name,
    SquadVisibility visibility,
    String ownerId,
    String sportType,
  );

  Future<void> applyToSquad(String squadId, String userId);

  Future<void> addUserToSquad(String squadId, String userId);
}
