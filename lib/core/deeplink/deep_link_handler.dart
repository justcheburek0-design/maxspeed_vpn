import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class DeepLinkHandler {
  static const _channel = MethodChannel('mxspd/deeplink');
  static final _controller = StreamController<String>.broadcast();
  static bool _initialized = false;

  static Stream<String> get onLink => _controller.stream;

  static void init() {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      _initWeb();
    } else {
      _initMobile();
    }
  }

  static void _initMobile() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onLink') {
        final link = call.arguments as String?;
        if (link != null && link.isNotEmpty) {
          _controller.add(link);
        }
      }
    });
  }

  static void _initWeb() {
    // On web, deep links are handled via URL fragment or query params
    // The web app checks window.location on load
    // For now, web doesn't support runtime deep links (page reload needed)
  }

  static Future<String?> getInitialLink() async {
    if (kIsWeb) {
      // On web, the URL itself is the deep link
      // Handled by JavaScript interop or URL parsing
      return null;
    }

    try {
      final link = await _channel.invokeMethod<String>('getInitialLink');
      return link;
    } catch (e) {
      debugPrint('DeepLink getInitialLink error: $e');
      return null;
    }
  }

  static void dispose() {
    _controller.close();
  }
}
