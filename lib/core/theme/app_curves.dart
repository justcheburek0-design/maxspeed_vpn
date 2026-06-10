import 'package:flutter/animation.dart';

class AppCurves {
  AppCurves._();
  static const Curve standard = Curves.easeInOut;
  static const Curve accelerate = Curves.easeIn;
  static const Curve decelerate = Curves.easeOut;
  static const Curve sharp = Curves.easeInOutCubic;
  static const Curve bounce = Curves.elasticOut;
  static const Curve spring = Curves.elasticInOut;
  static const Curve fast = Curves.easeInOutQuart;
  static const Curve smooth = Curves.easeInOutCubicEmphasized;
}
