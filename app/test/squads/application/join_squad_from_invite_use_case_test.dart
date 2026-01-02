import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/features/squads/application/join_squad_from_invite_use_case.dart';
import 'package:app/features/squads/domain/repositories/invite_code_storage.dart';
import 'package:app/features/squads/domain/repositories/squad_repository.dart';

class _MockSquadRepository extends Mock implements SquadRepository {}

class _MockInviteCodeStorage extends Mock implements InviteCodeStorage {}

void main() {
  late _MockSquadRepository squadRepository;
  late _MockInviteCodeStorage inviteCodeStorage;
  late JoinSquadFromInviteUseCase useCase;

  setUp(() {
    squadRepository = _MockSquadRepository();
    inviteCodeStorage = _MockInviteCodeStorage();
    useCase = JoinSquadFromInviteUseCase(squadRepository, inviteCodeStorage);
  });

  test('returns null when no invite code is stored', () async {
    when(() => inviteCodeStorage.readCode()).thenAnswer((_) async => null);

    final result = await useCase.execute();

    expect(result, isNull);
    verifyNever(() => squadRepository.joinSquadByCode(any()));
    verifyNever(() => inviteCodeStorage.clear());
  });

  test('joins squad with stored code and clears storage on success', () async {
    when(() => inviteCodeStorage.readCode()).thenAnswer((_) async => 'abc');
    when(
      () => squadRepository.joinSquadByCode('abc'),
    ).thenAnswer((_) async => 'squad-123');
    when(() => inviteCodeStorage.clear()).thenAnswer((_) async {});

    final result = await useCase.execute();

    expect(result, 'squad-123');
    verify(() => squadRepository.joinSquadByCode('abc')).called(1);
    verify(() => inviteCodeStorage.clear()).called(1);
  });

  test('clears storage and rethrows on failure', () async {
    when(() => inviteCodeStorage.readCode()).thenAnswer((_) async => 'abc');
    when(
      () => squadRepository.joinSquadByCode('abc'),
    ).thenThrow(Exception('invalid'));
    when(() => inviteCodeStorage.clear()).thenAnswer((_) async {});

    await expectLater(useCase.execute(), throwsException);
    verify(() => inviteCodeStorage.clear()).called(1);
  });
}
