import 'package:flutter/foundation.dart';

enum VpnProtocol { naive, vless, vmess, trojan, shadowsocks, wireguard, tuic, hysteria, xhttp }

extension VpnProtocolExt on VpnProtocol {
  String get displayName {
    switch (this) {
      case VpnProtocol.naive: return 'Naive';
      case VpnProtocol.vless: return 'VLESS';
      case VpnProtocol.vmess: return 'VMess';
      case VpnProtocol.trojan: return 'Trojan';
      case VpnProtocol.shadowsocks: return 'Shadowsocks';
      case VpnProtocol.wireguard: return 'WireGuard';
      case VpnProtocol.tuic: return 'TUIC';
      case VpnProtocol.hysteria: return 'Hysteria';
      case VpnProtocol.xhttp: return 'XHTTP';
    }
  }

  String get shortName => displayName;
}

enum VpnSecurity { none, tls, reality }

extension VpnSecurityExt on VpnSecurity {
  String get displayName {
    switch (this) {
      case VpnSecurity.none: return 'None';
      case VpnSecurity.tls: return 'TLS';
      case VpnSecurity.reality: return 'REALITY';
    }
  }
}

enum VpnConnectionState { disconnected, connecting, connected, disconnecting, error, reconnecting }

extension VpnConnectionStateExt on VpnConnectionState {
  String get displayName {
    switch (this) {
      case VpnConnectionState.disconnected: return 'Отключено';
      case VpnConnectionState.connecting: return 'Подключение...';
      case VpnConnectionState.connected: return 'Подключено';
      case VpnConnectionState.disconnecting: return 'Отключение...';
      case VpnConnectionState.error: return 'Ошибка';
      case VpnConnectionState.reconnecting: return 'Переподключение...';
    }
  }

  bool get isConnected => this == VpnConnectionState.connected;
  bool get isConnecting => this == VpnConnectionState.connecting || this == VpnConnectionState.reconnecting;
}

class VpnServer {
  final String id;
  final String name;
  final String address;
  final int port;
  final VpnProtocol protocol;
  final VpnSecurity security;
  final String? username;
  final String? uuid;
  final String? sni;
  final String? fingerprint;
  final String? publicKey;
  final String? shortId;
  final String? path;
  final String? host;
  final String? alpn;
  final String? flow;
  final String? mode;
  final Map<String, dynamic> rawConfig;
  final bool isFavorite;
  final int? ping;
  final String? country;
  final String? flag;

  const VpnServer({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    required this.protocol,
    this.security = VpnSecurity.none,
    this.username,
    this.uuid,
    this.sni,
    this.fingerprint,
    this.publicKey,
    this.shortId,
    this.path,
    this.host,
    this.alpn,
    this.flow,
    this.mode,
    this.rawConfig = const {},
    this.isFavorite = false,
    this.ping,
    this.country,
    this.flag,
  });

  VpnServer copyWith({
    String? id, String? name, String? address, int? port,
    VpnProtocol? protocol, VpnSecurity? security, String? username,
    String? uuid, String? sni, String? fingerprint,
    String? publicKey, String? shortId, String? path, String? host,
    String? alpn, String? flow, String? mode, Map<String, dynamic>? rawConfig,
    bool? isFavorite, int? ping, String? country, String? flag,
  }) {
    return VpnServer(
      id: id ?? this.id, name: name ?? this.name,
      address: address ?? this.address, port: port ?? this.port,
      protocol: protocol ?? this.protocol, security: security ?? this.security,
      username: username ?? this.username,
      uuid: uuid ?? this.uuid, sni: sni ?? this.sni,
      fingerprint: fingerprint ?? this.fingerprint,
      publicKey: publicKey ?? this.publicKey, shortId: shortId ?? this.shortId,
      path: path ?? this.path, host: host ?? this.host,
      alpn: alpn ?? this.alpn, flow: flow ?? this.flow, mode: mode ?? this.mode,
      rawConfig: rawConfig ?? this.rawConfig,
      isFavorite: isFavorite ?? this.isFavorite,
      ping: ping ?? this.ping, country: country ?? this.country,
      flag: flag ?? this.flag,
    );
  }

  String get displayName => name.isNotEmpty ? name : '$address:$port';
  String get protocolTag => protocol.displayName;
  String get securityTag => security.displayName;
  String get pingText => ping != null ? '${ping}ms' : '—';
  String get rawLink => rawConfig['link'] as String? ?? '';
  bool get isXhttp => protocol == VpnProtocol.vless && (rawConfig['type'] == 'xhttp' || path != null);

  @override
  bool operator ==(Object other) => identical(this, other) || other is VpnServer && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

class VpnSubscription {
  final String id;
  final String name;
  final String url;
  final List<VpnServer> servers;
  final DateTime? expiresAt;
  final bool isActive;
  final int uploadBytes;
  final int downloadBytes;
  final int totalBytes;
  final DateTime? lastUpdated;

  const VpnSubscription({
    required this.id,
    required this.name,
    required this.url,
    this.servers = const [],
    this.expiresAt,
    this.isActive = true,
    this.uploadBytes = 0,
    this.downloadBytes = 0,
    this.totalBytes = 0,
    this.lastUpdated,
  });

  int get daysRemaining => expiresAt == null ? -1 : expiresAt!.difference(DateTime.now()).inDays;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  double get dataUsedGB => (uploadBytes + downloadBytes) / (1024 * 1024 * 1024);
  bool get isUnlimited => totalBytes <= 0;
  double get dataProgress => (isUnlimited || totalBytes <= 0) ? 0 : (uploadBytes + downloadBytes) / totalBytes;
}

class VpnConnectionStats {
  final int bytesSent;
  final int bytesReceived;
  final int uploadSpeed;
  final int downloadSpeed;
  final Duration duration;
  final int? pingMs;
  final String? serverName;

  const VpnConnectionStats({
    this.bytesSent = 0,
    this.bytesReceived = 0,
    this.uploadSpeed = 0,
    this.downloadSpeed = 0,
    this.duration = Duration.zero,
    this.pingMs,
    this.serverName,
  });

  VpnConnectionStats copyWith({
    int? bytesSent, int? bytesReceived, int? uploadSpeed,
    int? downloadSpeed, Duration? duration, int? pingMs, String? serverName,
  }) => VpnConnectionStats(
    bytesSent: bytesSent ?? this.bytesSent,
    bytesReceived: bytesReceived ?? this.bytesReceived,
    uploadSpeed: uploadSpeed ?? this.uploadSpeed,
    downloadSpeed: downloadSpeed ?? this.downloadSpeed,
    duration: duration ?? this.duration,
    pingMs: pingMs ?? this.pingMs,
    serverName: serverName ?? this.serverName,
  );
}

enum VpnLogLevel { debug, info, warning, error }

class VpnLogEntry {
  final String id;
  final DateTime timestamp;
  final VpnLogLevel level;
  final String message;
  final String? details;

  const VpnLogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    this.details,
  });
}
