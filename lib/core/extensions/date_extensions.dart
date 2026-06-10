extension DateTimeExt on DateTime {
  String get formatted => '${day.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}.$year';
  String get timeFormatted => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  String get dateTimeFormatted => '$formatted $timeFormatted';
  bool get isToday { final n = DateTime.now(); return year == n.year && month == n.month && day == n.day; }
  bool get isYesterday { final y = DateTime.now().subtract(const Duration(days: 1)); return year == y.year && month == y.month && day == y.day; }
}
