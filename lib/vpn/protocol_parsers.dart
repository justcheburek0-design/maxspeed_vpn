import '../data/models/vpn_models.dart';
import 'vless_parser.dart';

class ProtocolParsers {
  ProtocolParsers._();
  static VpnServer parseLink(String link, {String? name}) {
    final t = link.trim();
    if (t.startsWith('naive+')) {
      final clean = t
          .replaceAll('naive+https://', 'https://')
          .replaceAll('naive+http://', 'http://');
      final u = Uri.parse(clean);
      final parts = u.userInfo.split(':');
      return VpnServer(
        id: u.host + ':' + u.port.toString(),
        name: name ?? (u.host + ':' + u.port.toString()),
        address: u.host,
        port: u.port > 0 ? u.port : 443,
        protocol: VpnProtocol.naive,
        username: parts.first,
        rawConfig: {'raw': t},
      );
    }
    if (t.startsWith('vless://')) return VlessParser.parse(t, name: name);
    throw FormatException('Unsupported protocol: ' + t.split(':').first);
  }
  static List<VpnServer> parseSubscription(String content) {
    final servers = <VpnServer>[];
    for (final line in content.split(RegExp(r'[\r\n]+'))) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('#')) continue;
      try { servers.add(parseLink(t)); } catch (_) {}
    }
    return servers;
  }
}
