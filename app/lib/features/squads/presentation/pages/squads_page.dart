import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/squad.dart';
import '../../domain/entities/user_squad_role.dart';
import '../state/squads_notifier.dart';
import '../widgets/squad_list_item.dart';

class SquadsPage extends ConsumerStatefulWidget {
  const SquadsPage({super.key});

  @override
  ConsumerState<SquadsPage> createState() => _SquadsPageState();
}

class _SquadsPageState extends ConsumerState<SquadsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    Future.microtask(() =>
        ref.read(squadsNotifierProvider.notifier).loadSquads());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isGuest {
    final authEntity = ref.read(authStateProvider).value;
    return authEntity == null || authEntity.isAnonymous;
  }

  Future<void> _handleSquadTap(Squad squad) async {
    final notifier = ref.read(squadsNotifierProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    switch (squad.role) {
      case SquadRole.owner:
      case SquadRole.admin:
      case SquadRole.member:
        if (!mounted) {
          return;
        }
        context.go('/squads/${squad.squadId}');
        return;
      case SquadRole.pending:
        messenger.showSnackBar(
          const SnackBar(content: Text('Request already sent')),
        );
        return;
      case SquadRole.none:
        if (squad.visibility == SquadVisibility.private) {
          await _showApplyDialog(squad, notifier);
          return;
        }
        if (!mounted) {
          return;
        }
        context.go('/squads/${squad.squadId}');
        return;
      case SquadRole.declined:
      case SquadRole.removed:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('You cannot access this squad'),
          ),
        );
        return;
      default:
      throw Exception('Invalid squad role: ${squad.role}');
    }
  }


  Future<void> _showApplyDialog(
    Squad squad,
    SquadsNotifier notifier,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply to Squad'),
        content: Text('Apply to join ${squad.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await notifier.applyToSquad(squad.squadId);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    final notifier = ref.read(squadsNotifierProvider.notifier);
    var visibility = SquadVisibility.public;
    final nameController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create squad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Squad name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SquadVisibility>(
              initialValue: visibility,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Visibility',
              ),
              items: SquadVisibility.values
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(option.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                visibility = value ?? visibility;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await notifier.createSquad(nameController.text, visibility);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final squadsState = ref.watch(squadsNotifierProvider);

    if (squadsState.isLoading && squadsState.squads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (squadsState.squads.isEmpty) {
      return const Center(
        child: Text('No squads found. Create one to get started!'),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(squadsNotifierProvider.notifier).loadSquads(
                searchQuery: _searchController.text,
              ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: squadsState.squads.length,
        itemBuilder: (context, index) {
          final squad = squadsState.squads[index];
          return SquadListItem(
            squad: squad,
            isGuest: _isGuest,
            onTap: () => _handleSquadTap(squad),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final squadsState = ref.watch(squadsNotifierProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final error = squadsState.error;
      if (error != null && error.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        ref.read(squadsNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search squads',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => ref
                        .read(squadsNotifierProvider.notifier)
                        .loadSquads(searchQuery: value),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => ref
                      .read(squadsNotifierProvider.notifier)
                      .loadSquads(searchQuery: _searchController.text),
                  icon: const Icon(Icons.search),
                  label: const Text('Find'),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _isGuest
          ? null
          : FloatingActionButton.extended(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Squad'),
            ),
    );
  }
}
