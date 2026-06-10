import 'package:flutter/material.dart';
import '../../core/theme/app_themes.dart';
import '../../data/models/vpn_models.dart';
import '../../services/vpn_service.dart';
import '../widgets/glass_container.dart';

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
    // TODO: Load from subscription
    setState(() {
      _servers = [
        VpnServer(
          id: 'demo1', name: 'Ютуб РФ', address: '1.2.3.4', port: 443,
          protocol: VpnProtocol.vless, security: VpnSecurity.reality,
          uuid: 'demo-uuid-1', sni: 'example.com', fingerprint: 'chrome',
          publicKey: 'demo-pubkey', shortId: 'abcd1234',
          mode: 'xhttp', path: '/xhttp', host: 'example.com',
          country: 'RU', flag: '🇷🇺', rawConfig: {'link': 'vless://demo'},
        ),
        VpnServer(
          id: 'demo2', name: 'Россия', address: '5.6.7.8', port: 443,
          protocol: VpnProtocol.vless, security: VpnSecurity.tls,
          uuid: 'demo-uuid-2', sni: 'example2.com', fingerprint: 'chrome',
          country: 'RU', flag: '🇷🇺', rawConfig: {'link': 'vless://demo2'},
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Серверы', style: TextStyle(color: theme.textPrimary)),
        iconTheme: IconThemeData(color: theme.textPrimary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                style: TextStyle(color: theme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Поиск серверов...',
                  hintStyle: TextStyle(color: theme.textMuted),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: theme.textMuted),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
          Expanded(
            child: _loading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filtered.length,
                  itemBuilder: (c, i) => _serverCard(c, theme, _filtered[i]),
                ),
          ),
        ],
      ),
    );
  }

  Widget _serverCard(BuildContext c, AppTheme theme, VpnServer server) {
    final isActive = widget.vpnService.activeServer?.id == server.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        tint: isActive ? theme.primary.withValues(alpha: 0.08) : null,
        borderColor: isActive ? theme.primary.withValues(alpha: 0.3) : null,
        child: InkWell(
          onTap: () => _connect(server),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Text(server.flag ?? '🌐', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(server.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _badge(c, theme, server.protocol.displayName, theme.protocolColor(server.security)),
                        const SizedBox(width: 6),
                        if (server.security != VpnSecurity.none)
                          _badge(c, theme, server.security.displayName, theme.protocolReality),
                        const SizedBox(width: 6),
                        if (server.isXhttp)
                          _badge(c, theme, 'XHTTP', theme.protocolXhttp),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (server.ping != null)
                    Text(server.pingText, style: TextStyle(fontSize: 13, color: _pingColor(theme, server.ping!))),
                  const SizedBox(height: 4),
                  Icon(
                    isActive ? Icons.check_circle : Icons.chevron_right,
                    color: isActive ? theme.success : theme.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(BuildContext c, AppTheme theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }

  Color _pingColor(AppTheme theme, int ping) {
    if (ping < 100) return theme.success;
    if (ping < 300) return theme.warning;
    return theme.error;
  }

  void _connect(VpnServer server) {
    widget.vpnService.connect(server);
    Navigator.pop(context);
  }
}

extension _ServerExt on VpnServer {
  bool get isXhttp => rawConfig['link']?.toString().contains('type=xhttp') == true;
}
