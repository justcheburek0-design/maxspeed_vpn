class NaiveLink {
  final String username;
  final String host;
  final int port;
  final String raw;
  const NaiveLink({required this.username, required this.host, required this.port, required this.raw});
  String get address => '$host:$port';
  @override String toString() => 'NaiveLink($username@$host:$port)';
}

class NaiveParser {
  static NaiveLink parse(String link) {
    try {
      final uri = Uri.parse(link);
      final parts = uri.userInfo.split(':');
      return NaiveLink(username: parts.first, host: uri.host, port: uri.port > 0 ? uri.port : 443, raw: link);
    } catch (e) { throw FormatException('Invalid naive link: $e'); }
  }
  static bool isValid(String link) { try { parse(link); return true; } catch (_) { return false; } }
}
