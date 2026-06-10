/// Data formatting utilities.
class Formatters {
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}д ${d.inHours % 24}ч';
    if (d.inHours > 0) return '${d.inHours}ч ${d.inMinutes % 60}м';
    if (d.inMinutes > 0) return '${d.inMinutes}м ${d.inSeconds % 60}с';
    return '${d.inSeconds}с';
  }

  static String formatSpeed(int bytesPerSecond) => '${formatBytes(bytesPerSecond)}/s';
  static String formatPing(int ms) => '$ms ms';
  static String formatDate(DateTime dt) => '${dt.day}.${dt.month}.${dt.year}';
  static String formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  static String formatDateTime(DateTime dt) => '${formatDate(dt)} ${formatTime(dt)}';
}
