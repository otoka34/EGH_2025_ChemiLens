// lib/main.dart
import 'package:flutter/material.dart';
import 'routes/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChemiLensApp());
}

class ChemiLensApp extends StatelessWidget {
  const ChemiLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ChemiLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F1A2B)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1A2B), // ← ネイビー
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF0F1A2B),
          unselectedItemColor: Colors.black87,
          showSelectedLabels: false,
          showUnselectedLabels: false,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
