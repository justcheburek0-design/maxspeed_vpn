import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();
  static const List<BoxShadow> none = [];
  static const List<BoxShadow> sm = [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1))];
  static const List<BoxShadow> md = [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))];
  static const List<BoxShadow> lg = [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4))];
  static const List<BoxShadow> xl = [BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8))];
  static const List<BoxShadow> xxl = [BoxShadow(color: Color(0x26000000), blurRadius: 32, offset: Offset(0, 12))];
  static const List<BoxShadow> glow = [BoxShadow(color: Color(0x4038BDF8), blurRadius: 20, offset: Offset(0, 0))];
  static const List<BoxShadow> dark = xxl;
  static const List<BoxShadow> card = md;
  static const List<BoxShadow> glowSuccess = [BoxShadow(color: Color(0x4034D399), blurRadius: 20, offset: Offset(0, 0))];
}
