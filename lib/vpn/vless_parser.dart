import '../data/models/vpn_models.dart';

class VlessParser {
  static VpnServer parse(String link, {String? name}) {
    try {
      final uri = Uri.parse(link);
      return VpnServer(id: uri.userInfo, name: name ?? Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : '${uri.host}:${uri.port}'), address: uri.host, port: uri.port > 0 ? uri.port : 443, protocol: VpnProtocol.vless, username: uri.userInfo, rawConfig: {'uuid': uri.userInfo, 'host': uri.host, 'port': uri.port, 'security': uri.queryParameters['security'] ?? '', 'sni': uri.queryParameters['sni'] ?? uri.queryParameters['peer'] ?? '', 'path': uri.queryParameters['path'] ?? ''});
    } catch (e) { throw FormatException('Invalid VLESS link: $e'); }
  }
  static bool isValid(String link) { try { parse(link); return true; } catch (_) { return false; } }
}
