import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_themes.dart';
import '../../data/models/vpn_models.dart';
import '../../services/vpn_service.dart';
import '../../vpn/vless_parser.dart';
import '../../vpn/subscription_parser.dart';

class ServersScreen extends StatefulWidget {
  final VpnService vpnService;
  const ServersScreen({super.key, required this.vpnService});
  @override State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  List<VpnServer> _servers = [];
  List<VpnSubscription> _subscriptions = [];
  bool _loading = false;
  String _searchQuery = '';
  int _selectedSubIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final subUrl = prefs.getString('subscription_url') ?? '';
    final subName = prefs.getString('subscription_name') ?? 'MaxSpeedVPN';
    final subExpiry = prefs.getString('subscription_expiry') ?? '';

    if (subUrl.isNotEmpty) {
      try {
        final servers = await _fetchSubscription(subUrl);
        if (servers.isNotEmpty) {
          _servers = servers;
          _subscriptions = [
            VpnSubscription(
              id: 'sub_1',
              name: subName,
              url: subUrl,
              expiresAt: subExpiry.isNotEmpty ? DateTime.tryParse(subExpiry) : null,
            ),
          ];
          await prefs.setStringList('servers', servers.map((s) => s.rawConfig['link'] as String? ?? '').where((l) => l.isNotEmpty).toList());
          setState(() => _loading = false);
          return;
        }
      } catch (e) {
        debugPrint('Subscription load error: $e');
      }
    }

    final cachedLinks = prefs.getStringList('servers') ?? [];
    if (cachedLinks.isNotEmpty) {
      _servers = cachedLinks
          .map((l) => VlessParser.parseToServer(l))
          .whereType<VpnServer>()
          .toList();
    }

    if (_servers.isEmpty) {
      _servers = _demoServers();
    }

    setState(() => _loading = false);
  }

  Future<List<VpnServer>> _fetchSubscription(String url) async {
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      return SubscriptionParser.parse(body);
    }
    return [];
  }

  List<VpnServer> _demoServers() {
    return [
      VpnServer(
        id: 'demo1', name: 'Ютуб РФ', address: '1.2.3.4', port: 443,
        protocol: VpnProtocol.vless, security: VpnSecurity.reality,
        uuid: 'demo-uuid-1', sni: 'example.com', fingerprint: 'chrome',
        publicKey: 'demo-pubkey', shortId: 'abcd1234',
        mode: 'xhttp', path: '/xhttp', host: 'example.com',
        country: 'RU', flag: '🇷🇺', rawConfig: {'link': 'vless://demo'},
        ping: 45,
      ),
      VpnServer(
        id: 'demo2', name: 'Россия', address: '5.6.7.8', port: 443,
        protocol: VpnProtocol.vless, security: VpnSecurity.tls,
        uuid: 'demo-uuid-2', sni: 'example2.com', fingerprint: 'chrome',
        country: 'RU', flag: '🇷🇺', rawConfig: {'link': 'vless://demo2'},
        ping: 120,
      ),
      VpnServer(
        id: 'demo3', name: 'Германия', address: '9.10.11.12', port: 443,
        protocol: VpnProtocol.vless, security: VpnSecurity.reality,
        uuid: 'demo-uuid-3', sni: 'google.com', fingerprint: 'chrome',
        publicKey: 'demo-pubkey-3', shortId: 'efgh5678',
        mode: 'tcp', host: 'google.com',
        country: 'DE', flag: '🇩🇪', rawConfig: {'link': 'vless://demo3'},
        ping: 180,
      ),
    ];
  }

  List<VpnServer> get _filtered {
    if (_searchQuery.isEmpty) return _servers;
    return _servers.where((s) =>
      s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      s.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      s.protocol.displayName.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.bgPrimary,
              theme.bgPrimary,
              theme.primary.withValues(alpha: 0.02),
              theme.bgPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, theme),
              if (_subscriptions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSubscriptionCard(context, theme),
              ],
              const SizedBox(height: 12),
              _buildSearchBar(theme),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: theme.primary))
                    : _buildServerList(context, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(ctx),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.onSurface, size: 20),
          ),
          const SizedBox(width: 4),
          Text(
            'Серверы',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _loadData,
            icon: Icon(Icons.refresh_rounded, color: theme.onSurfaceVariant, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext ctx, AppTheme theme) {
    final sub = _subscriptions[_selectedSubIndex];
    final daysLeft = sub.daysRemaining > 0 ? sub.daysRemaining : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.subscriptions_outlined, color: theme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.onSurface,
                        ),
                      ),
                      if (daysLeft != null)
                        Text(
                          'Осталось $daysLeft дн.',
                          style: TextStyle(
                            fontSize: 12,
                            color: daysLeft < 7 ? theme.error : theme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_servers.length} серверов',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(color: theme.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Поиск серверов...',
          hintStyle: TextStyle(color: theme.outline, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: theme.outline, size: 20),
          filled: true,
          fillColor: theme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.primary.withValues(alpha: 0.5)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildServerList(BuildContext ctx, AppTheme theme) {
    final servers = _filtered;
    if (servers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dns_outlined, size: 48, color: theme.outline),
            const SizedBox(height: 12),
            Text('Серверы не найдены', style: TextStyle(color: theme.onSurfaceVariant)),
          ],
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: servers.length,
      itemBuilder: (c, i) => _serverTile(ctx, theme, servers[i]),
    );
  }

  Widget _serverTile(BuildContext c, AppTheme theme, VpnServer server) {
    final isActive = widget.vpnService.activeServer?.id == server.id;
    final pingColor = _pingColor(theme, server.ping ?? 999);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _connect(server),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isActive ? theme.primary.withValues(alpha: 0.08) : theme.surface,
              border: Border.all(
                color: isActive ? theme.primary.withValues(alpha: 0.4) : theme.outlineVariant,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(server.flag ?? '🌐', style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          _badge(theme, server.protocol.displayName, theme.primary),
                          if (server.security != VpnSecurity.none)
                            _badge(theme, server.security.displayName, theme.protocolColor(server.security)),
                          if (server.isXhttp)
                            _badge(theme, 'XHTTP', theme.protocolXhttp),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (server.ping != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: pingColor),
                          ),
                          const SizedBox(width: 4),
                          Text('${server.ping}ms', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: pingColor)),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (isActive)
                      Icon(Icons.check_circle_rounded, size: 18, color: theme.success)
                    else
                      Icon(Icons.chevron_right_rounded, size: 20, color: theme.outline),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(AppTheme theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _pingColor(AppTheme theme, int ping) {
    if (ping < 100) return theme.success;
    if (ping < 300) return theme.warning;
    return theme.error;
  }

  void _connect(VpnServer server) {
    widget.vpnService.connect(server).then((success) {
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось подключиться. Проверьте настройки.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }
}
