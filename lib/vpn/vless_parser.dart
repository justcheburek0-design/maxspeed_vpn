import 'package:flutter/foundation.dart';
import '../../data/models/vpn_models.dart';

class VlessLink {
  final String uuid;
  final String address;
  final int port;
  final String name;
  final VpnProtocol protocol;
  final VpnSecurity security;
  final String? sni;
  final String? fingerprint;
  final String? publicKey;
  final String? shortId;
  final String? path;
  final String? host;
  final String? alpn;
  final String? flow;
  final String? network;
  final String? mode;
  final String? spx;
  final String? encryption;
  final String raw;
  final String? description;

  const VlessLink({
    required this.uuid,
    required this.address,
    required this.port,
    required this.name,
    this.protocol = VpnProtocol.vless,
    this.security = VpnSecurity.none,
    this.sni,
    this.fingerprint,
    this.publicKey,
    this.shortId,
    this.path,
    this.host,
    this.alpn,
    this.flow,
    this.network,
    this.mode,
    this.spx,
    this.encryption,
    required this.raw,
    this.description,
  });

  VpnServer toServer() {
    return VpnServer(
      id: '${address}_${port}_$uuid',
      name: name,
      address: address,
      port: port,
      protocol: VpnProtocol.vless,
      security: security,
      uuid: uuid,
      sni: sni,
      fingerprint: fingerprint,
      publicKey: publicKey,
      shortId: shortId,
      path: path,
      host: host,
      alpn: alpn,
      flow: isReality && (flow == null || flow!.isEmpty)
          ? 'xtls-rprx-vision'
          : flow,
      rawConfig: {'link': raw},
      description: description,
    );
  }

  bool get isReality => security == VpnSecurity.reality;
  bool get isTls => security == VpnSecurity.tls;
  bool get isXhttp => network == 'xhttp';
}

class VlessParser {
  static VlessLink? parse(String link) {
    try {
      if (!link.startsWith('vless://')) return null;
      final uri = Uri.parse(link);
      if (uri.scheme != 'vless') return null;
      final uuid = uri.userInfo;
      if (uuid.isEmpty) return null;

      VpnSecurity security = VpnSecurity.none;
      final sec =
          uri.queryParameters['security'] ?? uri.queryParameters['secure'];
      if (sec != null) {
        switch (sec.toLowerCase()) {
          case 'reality':
            security = VpnSecurity.reality;
            break;
          case 'tls':
          case 'ssl':
            security = VpnSecurity.tls;
            break;
        }
      }

      String name = '';
      final fragment = uri.fragment;
      if (fragment.isNotEmpty) name = Uri.decodeComponent(fragment);

      return VlessLink(
        uuid: uuid,
        address: uri.host,
        port: uri.port,
        name: name,
        protocol: VpnProtocol.vless,
        security: security,
        sni: uri.queryParameters['sni'] ?? uri.queryParameters['peer'],
        fingerprint:
            uri.queryParameters['fp'] ?? uri.queryParameters['fingerprint'],
        publicKey: uri.queryParameters['pbk'],
        shortId: uri.queryParameters['sid'],
        path: uri.queryParameters['path'],
        host: uri.queryParameters['host'],
        alpn: uri.queryParameters['alpn'],
        flow: uri.queryParameters['flow'],
        network: uri.queryParameters['type'] ?? uri.queryParameters['network'],
        mode: uri.queryParameters['mode'],
        spx: uri.queryParameters['spx'],
        encryption: uri.queryParameters['encryption'],
        raw: link,
      );
    } catch (e) {
      debugPrint('VLESS parse error: ' + e.toString());
      return null;
    }
  }

  static VpnServer? parseToServer(String link) => parse(link)?.toServer();

  static List<VpnServer> parseMultiple(List<String> links) {
    final servers = <VpnServer>[];
    for (final link in links) {
      final l = link.trim();
      if (l.isEmpty) continue;
      final s = parseToServer(l);
      if (s != null) servers.add(s);
    }
    return servers;
  }
}
