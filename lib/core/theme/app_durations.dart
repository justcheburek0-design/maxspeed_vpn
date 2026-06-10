class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  static const Duration pageTransition = Duration(milliseconds: 350);
  static const Duration snackbar = Duration(seconds: 3);
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration subscriptionCheck = Duration(hours: 1);
}
