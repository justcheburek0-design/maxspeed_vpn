import '../data/models/vpn_models.dart';

class LogService {
  final List<VpnLogEntry> _logs = [];
  List<VpnLogEntry> get logs => List.unmodifiable(_logs);
  void addLog(VpnLogLevel level, String message, {String? details}) {
    _logs.add(VpnLogEntry(id: DateTime.now().millisecondsSinceEpoch.toString(), timestamp: DateTime.now(), level: level, message: message, details: details));
    if (_logs.length > 500) _logs.removeAt(0);
  }
  void debug(String m) => addLog(VpnLogLevel.debug, m);
  void info(String m) => addLog(VpnLogLevel.info, m);
  void warning(String m) => addLog(VpnLogLevel.warning, m);
  void error(String m, {String? d}) => addLog(VpnLogLevel.error, m, details: d);
  void clear() => _logs.clear();
}
