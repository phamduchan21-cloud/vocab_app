class ApiConfig {
  /// FastAPI backend URL
  /// Khi build: flutter build web --dart-define=API_BASE_URL=https://vocab-api.onrender.com
  /// Mặc định: localhost cho dev
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Supabase project URL (for supabase_flutter SDK)
  static const String supabaseUrl =
      'https://tblagqcnhciqtmyhikoh.supabase.co';

  /// Supabase anon key (public, safe for client-side)
  static const String supabaseAnonKey =
      'sb_publishable_UQ593EFT4cqWU6ytOQz_Ug_6NlJpOEj';
}
