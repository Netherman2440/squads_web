
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod/riverpod.dart';

final supabase = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
