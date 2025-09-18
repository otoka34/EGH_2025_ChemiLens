import 'package:flutter/material.dart';

class AppColors {
  // インスタンス化を防ぐためのプライベートコンストラクタ
  AppColors._();

  // プライマリカラー
  static const Color color1 = Color(0xFFececed);
  static const Color color2 = Color(0xFF0F172A);
  static const Color color3 = Color(0xFF53CBF6);
  static const Color color4 = Color(0xFFE3579D);

  // 使いやすくするためのセマンティックカラー名
  static const Color background = color1;
  static const Color primaryDark = color2;
  static const Color primary = color3;
  static const Color textSecondary = color4;

  // 追加のセマンティックカラー
  static const Color textPrimary = color2;
  static const Color surface = color1;
  static const Color accent = color3;
  static const Color disabled = color4;

  // テーマ用のマテリアルカラースウォッチ
  static const MaterialColor primarySwatch =
      MaterialColor(0xFF5D49E9, <int, Color>{
        50: Color(0xFFECE9FD),
        100: Color(0xFFD0C8FA),
        200: Color(0xFFB1A4F7),
        300: Color(0xFF917FF4),
        400: Color(0xFF7A64F1),
        500: Color(0xFF5D49E9),
        600: Color(0xFF5442E6),
        700: Color(0xFF4839E3),
        800: Color(0xFF3D31DF),
        900: Color(0xFF2B21D9),
      });
}
