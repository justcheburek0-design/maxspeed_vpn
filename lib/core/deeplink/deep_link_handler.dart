import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class DeepLinkHandler {
  static const _channel = MethodChannel('mxspd/deeplink');
  static final _controller = StreamController<String>.broadcast();

  static Stream<String> get onLink => _controller.stream;

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onLink') {
        final link = call.arguments as String?;
        if (link != null && link.isNotEmpty) {
          _controller.add(link);
        }
      }
    });
  }

  static Future<String?> getInitialLink() async {
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
