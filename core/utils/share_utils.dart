import 'package:flutter/services.dart';

/// Share utility functions.
class ShareUtils {
  static Future<void> shareText(String text) async {
    // Fallback - copy to clipboard
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<String?> getClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }
}
