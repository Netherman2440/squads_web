import 'package:app/features/squads/domain/entities/squad_member.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/squads/application/change_squad_name_use_case.dart';
import 'package:app/features/squads/application/change_squad_visibility_use_case.dart';
import 'package:app/features/squads/application/get_squad_settings_members_use_case.dart';
import 'package:app/features/squads/application/modify_member_role_use_case.dart';
import 'package:app/features/squads/application/remove_member_use_case.dart';
import 'package:app/features/squads/application/update_squad_ranking_settings_use_case.dart';
import 'package:app/features/squads/domain/entities/squad.dart';

class SquadSettingsNotifier extends AsyncNotifier<List<SquadMember>> {
  String? _squadId;

  @override
  Future<List<SquadMember>> build() async {
    return [];
  }

  Future<void> promoteToAdmin(String userId) async {
    await _performAction(
      () => ref
          .read(modifyMemberRoleUseCaseProvider)
          .execute(
            squadId: _ensureSquadId(),
            userId: userId,
            newRole: SquadRole.admin,
          ),
    );
  }

  Future<void> demoteToMember(String userId) async {
    await _performAction(
      () => ref
          .read(modifyMemberRoleUseCaseProvider)
          .execute(
            squadId: _ensureSquadId(),
            userId: userId,
            newRole: SquadRole.member,
          ),
    );
  }

  Future<void> removeFromSquad(String userId) async {
    await _performAction(
      () => ref
          .read(removeMemberUseCaseProvider)
          .execute(squadId: _ensureSquadId(), userId: userId),
    );
  }

  Future<void> acceptRequest(String userId) async {
    await _performAction(
      () => ref
          .read(modifyMemberRoleUseCaseProvider)
          .execute(
            squadId: _ensureSquadId(),
            userId: userId,
            newRole: SquadRole.member,
          ),
    );
  }

  Future<void> declineRequest(String userId) async {
    await _performAction(
      () => ref
          .read(modifyMemberRoleUseCaseProvider)
          .execute(
            squadId: _ensureSquadId(),
            userId: userId,
            newRole: SquadRole.declined,
          ),
    );
  }

  Future<void> updateName(String newName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(changeSquadNameUseCaseProvider)
          .execute(squadId: _ensureSquadId(), newName: newName);
      return _fetchMembers();
    });
  }

  Future<void> updateVisibility(SquadVisibility newVisibility) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(changeSquadVisibilityUseCaseProvider)
          .execute(squadId: _ensureSquadId(), newVisibility: newVisibility);
      return _fetchMembers();
    });
  }

  Future<void> updateRankingSettings({
    required bool rankingUpdate,
    required int rankingMultiplier,
    required bool useExperienceFactor,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(updateSquadRankingSettingsUseCaseProvider)
          .execute(
            squadId: _ensureSquadId(),
            rankingUpdate: rankingUpdate,
            rankingMultiplier: rankingMultiplier,
            useExperienceFactor: useExperienceFactor,
          );
      return _fetchMembers();
    });
  }

  Future<void> _performAction(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await action();
      return _fetchMembers();
    });
  }

  Future<List<SquadMember>> _fetchMembers() {
    final squadId = _ensureSquadId();
    return ref.read(getSquadSettingsMembersUseCaseProvider).execute(squadId);
  }

  Future<void> load(String squadId) async {
    _squadId = squadId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchMembers);
  }

  String _ensureSquadId() {
    final squadId = _squadId;
    if (squadId == null) {
      throw StateError('Squad ID is not set for SquadSettingsNotifier');
    }
    return squadId;
  }
}

final squadSettingsProvider =
    AsyncNotifierProvider.autoDispose<SquadSettingsNotifier, List<SquadMember>>(
      SquadSettingsNotifier.new,
    );
