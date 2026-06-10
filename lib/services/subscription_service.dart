import '../data/models/vpn_models.dart';
import '../vpn/protocol_parsers.dart';

class SubscriptionService {
  final List<VpnSubscription> _subs = [];
  List<VpnSubscription> get subscriptions => List.unmodifiable(_subs);
  Future<void> addSubscription(String url, {String? name}) async {
    try {
      final server = ProtocolParsers.parseLink(url);
      _subs.add(VpnSubscription(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name ?? 'Subscription', url: url, servers: [server]));
    } catch (e) { throw FormatException('Failed to parse: $e'); }
  }
  void removeSubscription(String id) => _subs.removeWhere((s) => s.id == id);
  List<VpnServer> get allServers { final s = <VpnServer>[]; for (final sub in _subs) s.addAll(sub.servers); return s; }
}
