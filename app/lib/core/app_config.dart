class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static const int maxMatchesPlayed = 10;
  static const Duration inviteLinkValidity = Duration(hours: 24);
  static const double mobileWidth = 1000;
  static const double compactWidth = 2000;
  static const double wideLayoutWidth = 3000;

  static void validate() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) {
      missing.add('SUPABASE_URL');
    }
    if (supabaseAnonKey.isEmpty) {
      missing.add('SUPABASE_ANON_KEY');
    }

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required config: ${missing.join(', ')}. '
        'Provide them via --dart-define/--dart-define-from-file '
        '(for example: flutter run -d chrome --dart-define-from-file=.env).',
      );
    }
  }

  const AppConfig();
}
