import 'dart:math';

class Formatters {
  Formatters._();
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i.clamp(0, suffixes.length - 1)]}';
  }
  static String formatSpeed(int bps, {int decimals = 1}) {
    if (bps <= 0) return '0 B/s';
    const s = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    final i = (log(bps) / log(1024)).floor();
    return '${(bps / pow(1024, i)).toStringAsFixed(decimals)} ${s[i.clamp(0, s.length - 1)]}';
  }
  static String formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}ч ${d.inMinutes.remainder(60)}м ${d.inSeconds.remainder(60)}с';
    if (d.inMinutes > 0) return '${d.inMinutes}м ${d.inSeconds.remainder(60)}с';
    return '${d.inSeconds}с';
  }
  static String formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  static String formatDateTime(DateTime d) => '${formatDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  static String formatTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  static String formatPing(int ms) => ms < 0 ? '—' : '${ms}ms';
  static String formatPercentage(double v, {int d = 1}) => '${(v * 100).toStringAsFixed(d)}%';
}
