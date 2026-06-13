/// Глобальные константы приложения.
/// Все захардкоженные строки, числа и URL должны быть здесь.
library;

class AppConstants {
  AppConstants._();

  // ─── Брендинг ───
  static const String appName = 'MaxSpeedVPN';

  // ─── GitHub / API ───
  static const String githubRepoApi =
      'https://api.github.com/repos/justcheburek0-design/maxspeed_vpn/releases/latest';
}

// ─── sing-box конфигурация ───
class SingboxConstants {
  SingboxConstants._();

  // DNS
  static const String cloudflareDns = '1.1.1.1';
  static const String googleDns = '8.8.8.8';
  static const String dnsStrategy = 'prefer_ipv4';

  // TUN
  static const String tunInterfaceName = 'tun0';
  static const String tunAddress = '172.19.0.1/30';
  static const int tunMtu = 1500;
  static const String tunStack = 'system';

  // TLS / fingerprint
  static const String defaultFingerprint = 'chrome';

  // Shadowsocks
  static const String defaultSsMethod = 'aes-256-gcm';

  // Cache
  static const bool storeFakeIp = true;
}

// ─── Подписка (дефолтные значения для карточки) ───
class SubscriptionConstants {
  SubscriptionConstants._();

  static const String defaultName = 'MaxSpeedVPN';
  static const int defaultDaysLeft = 23;
  static const double defaultTotalGB = 100.0;
  static const double defaultUsedGB = 37.2;
  static const String creditLine = 'by envywook';
}

// ─── Настройки ───
class SettingsConstants {
  SettingsConstants._();

  static const String protocolDisplay = 'VLESS / REALITY';
  static const String engineDisplay = 'sing-box v1.13';
}
