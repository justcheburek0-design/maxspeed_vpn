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
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.8),
            radius: 1.0,
            colors: [
              theme.primary.withValues(alpha: 0.05),
              theme.bgPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Text('Серверы', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textPrimary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${_filtered.length}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.primary)),
                    ),
                  ],
                ),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: theme.bgCard,
                    border: Border.all(color: theme.border),
                  ),
                  child: TextField(
                    style: TextStyle(color: theme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Поиск серверов...',
                      hintStyle: TextStyle(color: theme.textMuted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixIcon: Icon(Icons.search, color: theme.textMuted, size: 20),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ),
              // Server list
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: theme.primary))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: _filtered.length,
                        itemBuilder: (c, i) => _serverCard(c, theme, _filtered[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serverCard(BuildContext c, AppTheme theme, VpnServer server) {
    final isActive = widget.vpnService.activeServer?.id == server.id;
    final pingColor = _pingColor(theme, server.ping ?? 999);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _connect(server),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isActive ? theme.primary.withValues(alpha: 0.08) : theme.bgCard,
              border: Border.all(
                color: isActive ? theme.primary.withValues(alpha: 0.4) : theme.border,
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [BoxShadow(color: theme.primary.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Row(
              children: [
                // Flag
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: theme.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.border),
                  ),
                  child: Center(
                    child: Text(server.flag ?? '🌐', style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(server.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _badge(theme, server.protocol.displayName, theme.protocolColor(server.security)),
                          if (server.security != VpnSecurity.none)
                            _badge(theme, server.security.displayName, theme.protocolReality),
                          if (server.isXhttp)
                            _badge(theme, 'XHTTP', theme.protocolXhttp),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right side: ping + status
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
                          Text('${server.ping}ms', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: pingColor)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.success.withValues(alpha: 0.15),
                        ),
                        child: Icon(Icons.check, size: 16, color: theme.success),
                      )
                    else
                      Icon(Icons.chevron_right, size: 20, color: theme.textMuted),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
    widget.vpnService.connect(server);
  }
}
