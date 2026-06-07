enum AppEnvironment { development, staging, production }

class EnvironmentConfig {
  EnvironmentConfig._();

  static const String rawName =
      String.fromEnvironment('APP_ENV', defaultValue: 'production');

  static AppEnvironment get current {
    switch (rawName.toLowerCase()) {
      case 'development':
      case 'dev':
        return AppEnvironment.development;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.production;
    }
  }

  static bool get isProduction => current == AppEnvironment.production;

  static String get analyticsPrefix => switch (current) {
        AppEnvironment.development => 'dev',
        AppEnvironment.staging => 'staging',
        AppEnvironment.production => 'prod',
      };
}
