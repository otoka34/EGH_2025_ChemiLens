import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/collection/history_screen.dart';

BottomNavigationBar buildBottomNav(
  BuildContext context,
  int currentIndex, {
  bool alwaysNavigate = false, // ← 追加：trueなら同じタブでも遷移する
}) {
  return BottomNavigationBar(
    currentIndex: currentIndex,
    onTap: (i) {
      // CameraScreen などで「Homeを押したら戻る」ために使用
      if (!alwaysNavigate && i == currentIndex) return;

      Widget screen;
      switch (i) {
        case 0:
          screen = const HistoryScreen();
          break;
        case 1:
          screen = const HomeScreen();
          break;
        default:
          screen = const HomeScreen();
      }
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => screen,
          transitionDuration: const Duration(milliseconds: 180),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.star_border), label: 'History'),
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
    ],
  );
}