import 'package:flutter/material.dart';

class SettingsService {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool _autoConnect = false;
  bool get autoConnect => _autoConnect;
  bool _killSwitch = false;
  bool get killSwitch => _killSwitch;
  String _protocol = 'naive';
  String get protocol => _protocol;
  Future<void> setThemeMode(ThemeMode m) async => _themeMode = m;
  Future<void> setAutoConnect(bool v) async => _autoConnect = v;
  Future<void> setKillSwitch(bool v) async => _killSwitch = v;
  Future<void> setProtocol(String v) async => _protocol = v;
}
