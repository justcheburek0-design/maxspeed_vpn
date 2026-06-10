import 'dart:convert';
import '../data/models/vpn_models.dart';

class SingboxConfigGenerator {
  SingboxConfigGenerator._();
  static String generate(VpnServer server) {
    return const JsonEncoder.withIndent('  ').convert({
      'outbounds': [_buildOutbound(server)],
      'route': {'final': 'proxy', 'rules': [{'outbound': 'proxy'}]},
      'dns': {'servers': [{'tag': 'google', 'address': 'tls://8.8.8.8'}]},
    });
  }

  static Map<String, dynamic> _extractNaiveCreds(Uri creds) {
    final parts = creds.userInfo.split(':');
    return {
      'username': parts.first,
      'userpass': parts.length > 1 ? parts[1] : '',
      'host': creds.host,
      'port': creds.port > 0 ? creds.port : 443,
    };
  }

  static Map<String, dynamic> _buildOutbound(VpnServer server) {
    switch (server.protocol) {
      case VpnProtocol.naive: return _buildNaive(server);
      case VpnProtocol.vless: return _buildVless(server);
      default: return _buildNaive(server);
    }
  }

  static Map<String, dynamic> _buildNaive(VpnServer s) {
    String un = s.username ?? '';
    String up = '';
    String h = s.address;
    int pt = s.port;
    final raw = s.rawConfig['raw'] as String?;
    if (raw != null && raw.startsWith('naive+')) {
      final clean = raw
          .replaceAll('naive+https://', 'https://')
          .replaceAll('naive+http://', 'http://');
      final creds = _extractNaiveCreds(Uri.parse(clean));
      un = creds['username'] as String;
      up = creds['userpass'] as String;
      h = creds['host'] as String;
      pt = creds['port'] as int;
    }
    return {
      'type': 'naive', 'tag': 'proxy',
      'server': h, 'port': pt,
      'username': un, 'password': up,
      'tls': {'enabled': true, 'server_name': h},
      'network': 'tcp',
    };
  }

  static Map<String, dynamic> _buildVless(VpnServer s) => {
    'type': 'vless', 'tag': 'proxy',
    'server': s.address, 'port': s.port,
    'uuid': s.username ?? s.id,
    'tls': {'enabled': true, 'server_name': s.rawConfig['sni'] ?? s.address},
    'network': 'tcp',
  };
}
