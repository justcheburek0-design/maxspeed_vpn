import 'package:flutter/material.dart';
import '../../core/theme/app_themes.dart';
import '../../data/models/vpn_models.dart';
import '../../services/vpn_service.dart';

class ServersScreen extends StatefulWidget {
  final VpnService vpnService;
  const ServersScreen({super.key, required this.vpnService});
  @override State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  List<VpnServer> _servers = [];
  bool _loading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  void _loadServers() {
    setState(() {
      _servers = [
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
    });
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
      backgroundColor: theme.bgPrimary,
      appBar: AppBar(
        backgroundColor: theme.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Серверы',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_filtered.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search field — Material3 filled style
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              hintText: 'Поиск серверов...',
              leading: Icon(Icons.search, color: theme.onSurfaceVariant),
              backgroundColor: WidgetStatePropertyAll(theme.surface),
              surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
              elevation: WidgetStatePropertyAll(0),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: theme.outlineVariant),
                ),
              ),
              hintStyle: WidgetStatePropertyAll(
                TextStyle(color: theme.onSurfaceVariant),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // Server list
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: theme.primary))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (c, i) => _serverTile(c, theme, _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _serverTile(BuildContext c, AppTheme theme, VpnServer server) {
    final isActive = widget.vpnService.activeServer?.id == server.id;
    final pingColor = _pingColor(theme, server.ping ?? 999);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _connect(server),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive ? theme.primaryContainer.withValues(alpha: 0.3) : theme.surface,
            border: Border.all(
              color: isActive ? theme.primary.withValues(alpha: 0.4) : theme.outlineVariant,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Flag
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(server.flag ?? '🌐', style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              // Name + protocol badges
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
                        _protocolBadge(theme, server.protocol.displayName, theme.primary),
                        if (server.security != VpnSecurity.none)
                          _protocolBadge(theme, server.security.displayName, theme.protocolColor(server.security)),
                        if (server.isXhttp)
                          _protocolBadge(theme, 'XHTTP', theme.protocolXhttp),
                      ],
                    ),
                  ],
                ),
              ),
              // Right: ping + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (server.ping != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: pingColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${server.ping}ms',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: pingColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (isActive)
                    Icon(Icons.check_circle, size: 18, color: theme.success)
                  else
                    Icon(Icons.chevron_right, size: 20, color: theme.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _protocolBadge(AppTheme theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _pingColor(AppTheme theme, int ping) {
    if (ping < 100) return theme.success;
    if (ping < 300) return theme.warning;
    return theme.error;
  }

  void _connect(VpnServer server) {
    widget.vpnService.connect(server);
  }
}
