import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment {
  dev,
  prod;

  static Environment get current {
    const env = String.fromEnvironment('ENV', defaultValue: 'prod');
    return Environment.values.firstWhere(
      (e) => e.name == env,
      orElse: () => Environment.prod,
    );
  }

  String get fileName {
    switch (this) {
      case Environment.dev:
        return '.env.dev';
      case Environment.prod:
        return '.env.prod';
    }
  }
}

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  const AppConfig();
}
