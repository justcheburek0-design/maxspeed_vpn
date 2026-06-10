import 'dart:convert';
import '../../data/models/vpn_models.dart';

class SingboxConfigGenerator {
  static String generate(VpnServer server) {
    final log = {
      'level': 'info',
      'timestamp': true,
      'disabled': false,
    };

    final dns = {
      'servers': [
        {'type': 'local', 'tag': 'local-dns'},
        {'type': 'https', 'tag': 'cloudflare-doh', 'server': '1.1.1.1'},
        {'type': 'https', 'tag': 'google-doh', 'server': '8.8.8.8'},
      ],
      'final': 'cloudflare-doh',
      'strategy': 'prefer_ipv4',
    };

    final inbounds = [
      {
        'type': 'tun',
        'tag': 'tun-in',
        'interface_name': 'tun0',
        'mtu': 1500,
        'address': ['172.19.0.1/30'],
        'auto_route': true,
        'auto_redirect': true,
        'stack': 'system',
      },
    ];

    final outbound = _buildOutbound(server);
    final outbounds = [
      {'type': 'direct', 'tag': 'direct-out'},
      {'type': 'block', 'tag': 'block-out'},
      {'type': 'dns', 'tag': 'dns-out'},
      outbound,
    ];

    final route = {
      'rules': [
        {'protocol': 'dns', 'outbound': 'dns-out'},
      ],
      'auto_detect_interface': true,
      'final': 'vpn',
    };

    final config = {
      'log': log,
      'dns': dns,
      'inbounds': inbounds,
      'outbounds': outbounds,
      'route': route,
      'experimental': {
        'cache_file': {
          'enabled': true,
          'store_fakeip': true,
        },
      },
    };

    return const JsonEncoder.withIndent('  ').convert(config);
  }

  static Map<String, dynamic> _buildOutbound(VpnServer server) {
    switch (server.protocol) {
      case VpnProtocol.vless:
        return _buildVlessOutbound(server);
      case VpnProtocol.trojan:
        return _buildTrojanOutbound(server);
      case VpnProtocol.shadowsocks:
        return _buildShadowsocksOutbound(server);
      default:
        return _buildVlessOutbound(server);
    }
  }

  static Map<String, dynamic> _buildVlessOutbound(VpnServer server) {
    final outbound = <String, dynamic>{
      'type': 'vless',
      'tag': 'vpn',
      'server': server.address,
      'server_port': server.port,
      'uuid': server.uuid ?? '',
    };

    if (server.flow != null && server.flow!.isNotEmpty && server.isReality) {
      outbound['flow'] = server.flow;
    }

    // Transport
    final transport = <String, dynamic>{};
    if (server.isXhttp) {
      transport['type'] = 'xhttp';
      if (server.path != null && server.path!.isNotEmpty) {
        transport['path'] = server.path;
      }
      if (server.host != null && server.host!.isNotEmpty) {
        transport['host'] = server.host;
      }
      if (server.mode != null && server.mode!.isNotEmpty) {
        transport['mode'] = server.mode;
      }
    }
    if (transport.isNotEmpty) {
      outbound['transport'] = transport;
    }

    // TLS
    final tls = <String, dynamic>{};
    if (server.isTls) {
      tls['enabled'] = true;
      if (server.sni != null && server.sni!.isNotEmpty) tls['server_name'] = server.sni;
      if (server.alpn != null && server.alpn!.isNotEmpty) tls['alpn'] = server.alpn!.split(',');
      tls['utls'] = {
        'enabled': true,
        'fingerprint': server.fingerprint ?? 'chrome',
      };
    } else if (server.isReality) {
      tls['enabled'] = true;
      if (server.sni != null && server.sni!.isNotEmpty) tls['server_name'] = server.sni;
      tls['utls'] = {
        'enabled': true,
        'fingerprint': server.fingerprint ?? 'chrome',
      };
      tls['reality'] = {
        'enabled': true,
        'short_id': server.shortId ?? '',
        'public_key': server.publicKey ?? '',
      };
    }
    if (tls.isNotEmpty) {
      outbound['tls'] = tls;
    }

    return outbound;
  }

  static Map<String, dynamic> _buildTrojanOutbound(VpnServer server) {
    return {
      'type': 'trojan',
      'tag': 'vpn',
      'server': server.address,
      'server_port': server.port,
      'password': server.uuid ?? '',
      'tls': {
        'enabled': true,
        'server_name': server.sni ?? server.address,
        'utls': {
          'enabled': true,
          'fingerprint': server.fingerprint ?? 'chrome',
        },
      },
    };
  }

  static Map<String, dynamic> _buildShadowsocksOutbound(VpnServer server) {
    final method = server.rawConfig['method'] as String? ?? 'aes-256-gcm';
    return {
      'type': 'shadowsocks',
      'tag': 'vpn',
      'server': server.address,
      'server_port': server.port,
      'method': method,
      'password': server.uuid ?? '',
    };
  }
}


