import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/squads/presentation/state/squads_notifier.dart';
import 'package:app/features/squads/presentation/widgets/squad_list_item.dart';
import 'package:app/features/squads/domain/entities/squad.dart';
import 'package:app/features/squads/domain/entities/user_squad_role.dart';
import 'package:app/features/users/presentation/state/user_notifier.dart';
import 'package:app/features/users/presentation/widgets/user_profile_card.dart';

class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});

  @override
  ConsumerState<UserPage> createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userNotifierProvider.notifier).loadUser();
      ref.read(squadsNotifierProvider.notifier).loadSquads();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(userNotifierProvider.notifier).loadUser();
    await ref.read(squadsNotifierProvider.notifier).loadSquads();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userNotifierProvider);
    final squadsState = ref.watch(squadsNotifierProvider);

    final profile = userState.profile;
    final mySquads = profile?.memberships ?? const [];
    final hasSquad = mySquads.any(
      (membership) => membership.role != SquadRole.none,
    );

    final text = hasSquad ? 'Add more' : 'Add your first squad';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            UserProfileCard(
              isLoading: userState.isLoading,
              user: profile?.user,
              error: userState.error,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My squads',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go('/squads'),
                    icon: const Icon(Icons.add),
                    label: Text(text),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (squadsState.isLoading && mySquads.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (mySquads.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'You are not a member of any squads yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mySquads.length,
                itemBuilder: (context, index) {
                  final item = mySquads[index];
                  final fallback = Squad(
                    squadId: item.squadId,
                    ownerId: '',
                    name: item.squadName,
                    visibility: SquadVisibility.public,
                    sportType: SportType.football,
                    createdAt: DateTime.now(),
                  );
                  final squad =
                      squadsState.value?.firstWhere(
                        (s) => s.squadId == item.squadId,
                        orElse: () => fallback,
                      ) ??
                      fallback;

                  return SquadListItem(
                    squad: squad,
                    isGuest: false,
                    onTap: () {
                      context.go('/squads/${squad.squadId}');
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
