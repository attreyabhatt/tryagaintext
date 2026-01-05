class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'https://tryagaintext.com',
  );

  static const String apiPath = '/api';
  static String get apiBaseUrl => '$baseUrl$apiPath';
}
