import 'package:flutter/material.dart';
import '../home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    // 表示 → 少し待って → フェードアウト → Homeにフェード遷移
    Future.microtask(() async {
      await Future.delayed(const Duration(milliseconds: 1600));
      if (!mounted) return;
      setState(() => _opacity = 0.0); // フェードアウト開始
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface, // テーマに馴染む背景
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          opacity: _opacity,
          // 見出し＋サブコピー（必要なら調整）
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'chemilens', // ご指定どおり小文字
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find molecules in everyday life',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
