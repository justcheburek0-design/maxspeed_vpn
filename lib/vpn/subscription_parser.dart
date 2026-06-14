import 'dart:convert';
import '../../data/models/vpn_models.dart';
import '../../data/models/country_flag.dart';
import 'vless_parser.dart';

class SubscriptionParser {
  static List<VpnServer> parse(String rawContent) {
    if (rawContent.isEmpty) return [];
    String content = rawContent.trim();

    // Try base64 decode first
    try {
      final decoded = utf8.decode(base64Decode(content));
      if (decoded.contains('vless://') || decoded.contains('vmess://') ||
          decoded.contains('trojan://') || decoded.contains('ss://')) {
        content = decoded;
      }
    } catch (_) {}

    final servers = <VpnServer>[];
    final lines = content.split(RegExp(r'[\r\n]+'));

    for (final line in lines) {
      final link = line.trim();
      if (link.isEmpty) continue;
      VpnServer? server;
      if (link.startsWith('vless://')) {
        server = VlessParser.parseToServer(link);
      } else if (link.startsWith('trojan://')) {
        server = _parseTrojan(link);
      } else if (link.startsWith('vmess://')) {
        server = _parseVmess(link);
      } else if (link.startsWith('ss://')) {
        server = _parseShadowsocks(link);
      } else if (link.startsWith('naive+https://') || link.startsWith('naive+http://')) {
        server = _parseNaive(link);
      }
      if (server != null) {
        final flag = CountryFlagUtil.extractFlag(server.name);
        final cleanName = flag != null ? CountryFlagUtil.stripFlag(server.name) : server.name;
        // Extract description: if name contains " | " or " — ", take the part after it
        String? description;
        String finalName = cleanName;
        final descSeparators = [' | ', ' — ', ' - ', ' :: '];
        for (final sep in descSeparators) {
          final idx = cleanName.indexOf(sep);
          if (idx > 0 && idx < cleanName.length - 3) {
            description = cleanName.substring(idx + sep.length).trim();
            finalName = cleanName.substring(0, idx).trim();
            if (description.isEmpty) description = null;
            break;
          }
        }
        servers.add(server.copyWith(flag: flag, name: finalName, description: description));
      }
    }
    return servers;
  }

  static VpnServer? _parseTrojan(String link) {
    try {
      final uri = Uri.parse(link);
      return VpnServer(
        id: 'trojan_' + uri.host + '_' + uri.port.toString() + '_' + uri.userInfo,
        name: uri.fragment.isNotEmpty ? Uri.decodeComponent(uri.fragment) : uri.host,
        address: uri.host, port: uri.port, protocol: VpnProtocol.trojan,
        security: VpnSecurity.tls, uuid: uri.userInfo,
        sni: uri.queryParameters['sni'], rawConfig: {'link': link},
      );
    } catch (_) { return null; }
  }

  static VpnServer? _parseVmess(String link) {
    try {
      final base64Str = link.substring(8);
      final decoded = utf8.decode(base64Decode(base64Str));
      final json = Map<String, dynamic>.from(jsonDecode(decoded));
      return VpnServer(
        id: 'vmess_' + (json['add'] ?? '') + '_' + (json['port']?.toString() ?? '') + '_' + (json['id'] ?? ''),
        name: json['ps'] ?? json['host'] ?? json['add'] ?? '',
        address: json['add'] ?? json['host'] ?? '',
        port: int.tryParse(json['port'].toString()) ?? 443,
        protocol: VpnProtocol.vmess,
        security: (json['tls'] == 'tls' || json['tls'] == '1') ? VpnSecurity.tls : VpnSecurity.none,
        uuid: json['id'], sni: json['sni'] ?? json['host'],
        host: json['host'], path: json['path'],
        rawConfig: {'link': link, ...json},
      );
    } catch (_) { return null; }
  }

  static VpnServer? _parseShadowsocks(String link) {
    try {
      final uri = Uri.parse(link);
      final userInfo = uri.userInfo;
      String? method;
      String? pass;
      if (userInfo.isNotEmpty) {
        try {
          final decoded = utf8.decode(base64Decode(userInfo));
          final parts = decoded.split(':');
          if (parts.length >= 2) { method = parts[0]; pass = parts.sublist(1).join(':'); }
        } catch (_) {
          final parts = userInfo.split(':');
          if (parts.length >= 2) { method = parts[0]; pass = parts.sublist(1).join(':'); }
        }
      }
      final name = uri.fragment.isNotEmpty ? Uri.decodeComponent(uri.fragment) : uri.host;
      return VpnServer(
        id: 'ss_' + uri.host + '_' + uri.port.toString() + '_' + (method ?? ''),
        name: name, address: uri.host, port: uri.port,
        protocol: VpnProtocol.shadowsocks, security: VpnSecurity.none,
        uuid: pass, rawConfig: {'link': link, 'method': method},
      );
    } catch (_) { return null; }
  }

  static VpnServer? _parseNaive(String link) {
    try {
      final uri = Uri.parse(link);
      final userInfo = uri.userInfo;
      String? username;
      String? password;
      if (userInfo.isNotEmpty) {
        final parts = userInfo.split(':');
        if (parts.length >= 2) {
          username = parts[0];
          password = parts.sublist(1).join(':');
        } else {
          username = userInfo;
        }
      }
      final name = uri.fragment.isNotEmpty ? Uri.decodeComponent(uri.fragment) : uri.host;
      return VpnServer(
        id: 'naive_' + uri.host + '_' + uri.port.toString() + '_' + (username ?? ''),
        name: name, address: uri.host, port: uri.port,
        protocol: VpnProtocol.naive, security: VpnSecurity.tls,
        username: username, uuid: password,
        rawConfig: {'link': link},
      );
    } catch (_) { return null; }
  }
}
