class Validators {
  Validators._();
  static bool isValidUrl(String url) { try { final u = Uri.parse(url); return u.hasScheme && (u.scheme == 'http' || u.scheme == 'https'); } catch (_) { return false; } }
  static bool isValidSubscriptionUrl(String url) { if (url.startsWith('naive+')) return isValidUrl(url.substring(6)); return isValidUrl(url) || url.contains('://'); }
  static bool isValidHost(String h) => h.isNotEmpty && !h.contains(' ');
  static bool isValidPort(int p) => p > 0 && p <= 65535;
  static String? validateRequired(String? v, {String f = 'Поле'}) => (v == null || v.trim().isEmpty) ? '$f обязательно' : null;
  static String? validateUrl(String? v) { if (v == null || v.trim().isEmpty) return 'URL обязателен'; if (!isValidSubscriptionUrl(v)) return 'Некорректный URL'; return null; }
}
