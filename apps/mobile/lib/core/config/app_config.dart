class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://172.27.181.149:3000/api/v1',
  );

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ywaxvsqpofnkwxdwhpdl.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3YXh2c3Fwb2Zua3d4ZHdocGRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyNDA1NDksImV4cCI6MjA5NTgxNjU0OX0.b7KAeSjYWybBCK84Q94NgOfV4MDhWFykbnErhjKQq64',
  );

  static const skipAuth = bool.fromEnvironment('SKIP_AUTH', defaultValue: false);
}
