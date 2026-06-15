/// Input validation utilities.
class Validators {
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'naive');
    } catch (_) {
      return false;
    }
  }

  static bool isValidEmail(String email) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  static bool isValidPort(String port) {
    final n = int.tryParse(port);
    return n != null && n > 0 && n <= 65535;
  }

  static bool isValidServerName(String name) => name.isNotEmpty && name.length <= 64;
  static bool isValidPassword(String pw) => pw.length >= 8 && pw.length <= 128;
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName обязательно';
    return null;
  }
}
