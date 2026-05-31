class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.3:3000/api/v1',
  );

  static const skipAuth = bool.fromEnvironment('SKIP_AUTH', defaultValue: false);
}
