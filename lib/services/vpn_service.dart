import 'dart:async';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../data/models/vpn_models.dart';

class VpnService {
  static const _channel = MethodChannel(AppConstants.methodChannelName);
  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnConnectionState get state => _state;
  VpnServer? _activeServer;
  VpnServer? get activeServer => _activeServer;
  final _stateController = StreamController<VpnConnectionState>.broadcast();
  Stream<VpnConnectionState> get stateStream => _stateController.stream;

  Future<void> connect(VpnServer server) async {
    _activeServer = server;
    _setState(VpnConnectionState.connecting);
    try {
      await _channel.invokeMethod('connect', {'server': server.address, 'port': server.port, 'protocol': server.protocol.name, 'username': server.username ?? '', 'rawConfig': server.rawConfig});
      _setState(VpnConnectionState.connected);
    } catch (e) { _setState(VpnConnectionState.error); rethrow; }
  }
  Future<void> disconnect() async {
    _setState(VpnConnectionState.disconnecting);
    try { await _channel.invokeMethod('disconnect'); _setState(VpnConnectionState.disconnected); } catch (e) { _setState(VpnConnectionState.error); rethrow; }
  }
  Future<void> toggle(VpnServer server) async { if (_state == VpnConnectionState.connected) { await disconnect(); } else { await connect(server); } }
  void _setState(VpnConnectionState s) { _state = s; _stateController.add(s); }
  void dispose() { _stateController.close(); }
}
