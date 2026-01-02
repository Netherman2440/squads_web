import 'package:app/core/error/failure.dart';
import 'package:app/core/error/supabase_error_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/global_dependencies.dart';

import '../../domain/entities/invite_link.dart';
import '../../domain/repositories/invite_links_repository.dart';

class SupabaseInviteLinksRepository implements InviteLinksRepository {
  final SupabaseClient _supabase;
  final Logger _logger = Logger('SupabaseInviteLinksRepository');

  SupabaseInviteLinksRepository(this._supabase);

  @override
  Future<InviteLink> createInviteLink(
    String squadId,
    String code,
    Duration validFor,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const UnauthorizedFailure();
    }

    try {
      final validUntil = DateTime.now().add(validFor).toUtc().toIso8601String();
      final response = await _supabase
          .from('invite_links')
          .upsert({
            'code': code,
            'squad_id': squadId,
            'valid_until': validUntil,
            'created_by': userId,
          }, onConflict: 'squad_id')
          .select()
          .single();

      return InviteLink.fromMap(Map<String, dynamic>.from(response));
    } catch (e, stack) {
      _logger.severe(
        'Failed to create invite link for squad $squadId',
        e,
        stack,
      );
      throw e.toFailure();
    }
  }

  @override
  Future<InviteLink?> getInviteLink(String squadId) async {
    try {
      final response = await _supabase
          .from('invite_links')
          .select()
          .eq('squad_id', squadId)
          .gt('valid_until', DateTime.now().toUtc().toIso8601String())
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return InviteLink.fromMap(Map<String, dynamic>.from(response));
    } catch (e, stack) {
      _logger.severe('Failed to load invite link for squad $squadId', e, stack);
      throw e.toFailure();
    }
  }
}

final inviteLinksRepositoryProvider = Provider<InviteLinksRepository>((ref) {
  final supabase = ref.read(supabaseProvider);
  return SupabaseInviteLinksRepository(supabase);
});
