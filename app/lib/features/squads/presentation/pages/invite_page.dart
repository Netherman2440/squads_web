import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/app_router.dart';
import 'package:app/core/app_config.dart';
import 'package:app/core/error/failure.dart';
import 'package:app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:app/features/squads/application/join_squad_from_invite_use_case.dart';
import 'package:app/features/squads/infrastructure/storage/invite_code_storage.dart';

class InvitePage extends ConsumerStatefulWidget {
  const InvitePage({super.key, required this.code});

  final String? code;

  @override
  ConsumerState<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends ConsumerState<InvitePage> {
  bool _joining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_persistCodeAndJoin);
  }

  Future<void> _persistCodeAndJoin() async {
    if (!mounted) {
      return;
    }
    final code = widget.code?.trim();
    if (code == null || code.isEmpty) {
      if (mounted) {
        setState(() {
          _error = 'Brak kodu zaproszenia.';
        });
      }
      return;
    }

    await ref
        .read(inviteCodeStorageProvider)
        .saveCode(code, AppConfig.inviteLinkValidity);

    await _attemptJoin();
  }

  Future<void> _attemptJoin() async {
    if (_joining) {
      return;
    }

    final auth = ref.read(authStateProvider).value;
    if (auth == null || auth.isAnonymous) {
      if (mounted) {
        context.goNamed(AppRoute.auth.name);
      }
      return;
    }

    setState(() {
      _joining = true;
      _error = null;
    });

    try {
      final squadId = await ref
          .read(joinSquadFromInviteUseCaseProvider)
          .execute();
      if (!mounted) {
        return;
      }
      if (squadId != null) {
        context.goNamed(
          AppRoute.squadDetails.name,
          pathParameters: {'squadId': squadId},
        );
        return;
      }
      if (mounted) {
        setState(() {
          _error = 'Kod zaproszenia nie jest już dostępny.';
        });
      }
    } catch (error) {
      await ref.read(inviteCodeStorageProvider).clear();
      if (!mounted) {
        return;
      }
      var message = 'Kod zaproszenia jest nieprawidłowy lub wygasł.';
      if (error is Failure && error.message.isNotEmpty) {
        message = error.message;
      }
      if (mounted) {
        setState(() {
          _error = message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _joining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.listen<AsyncValue>(authStateProvider, (previous, next) {
      next.whenOrNull(
        data: (data) {
          if (data != null && !data.isAnonymous) {
            _persistCodeAndJoin();
          }
        },
      );
    });
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link, size: 64),
              const SizedBox(height: 16),
              Text(
                'Dołączanie do składu...',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _attemptJoin,
                  child: const Text('Spróbuj ponownie'),
                ),
              ] else if (_joining)
                const CircularProgressIndicator()
              else
                const Text('Przekierowuję do składu'),
            ],
          ),
        ),
      ),
    );
  }
}
