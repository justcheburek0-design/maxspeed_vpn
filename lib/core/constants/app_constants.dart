class AppConstants {
  AppConstants._();
  static const String appName = 'MaxSpeedVPN';
  static const String appVersion = '1.0.0';
  static const String packageName = 'ru.maxspeed.maxspeed_vpn';
  static const String methodChannelName = 'maxspeed.vpn';
  static const String routeHome = '/';
  static const String routeServers = '/servers';
  static const String routeSettings = '/settings';
  static const String routeLogs = '/logs';
  static const String routeOnboarding = '/onboarding';
  static const String keyThemeMode = 'theme_mode';
  static const String keyAutoConnect = 'auto_connect';
  static const String keyKillSwitch = 'kill_switch';
  static const String keyProtocol = 'protocol';
  static const String keyLastServer = 'last_server';
  static const String keySubscriptionUrl = 'subscription_url';
  static const String keyFirstLaunch = 'first_launch';
  static const bool defaultAutoConnect = false;
  static const bool defaultKillSwitch = false;
  static const String defaultProtocol = 'naive';
  static const int maxServers = 1000;
  static const int maxSubscriptions = 10;
  static const int maxLogEntries = 500;
  static const int connectionTimeout = 30;
  static const String supportUrl = 'https://t.me/maxspeedvpn_support';
  static const String privacyPolicyUrl = 'https://maxspeed.vpn/privacy';
  static const String termsUrl = 'https://maxspeed.vpn/terms';
}
