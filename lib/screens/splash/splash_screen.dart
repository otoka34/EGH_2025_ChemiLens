import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      context.go('/');
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
          child: SvgPicture.asset(
            'assets/images/Chemilens.svg',
            width: 240,
          ),
        ),
      ),
    );
  }
}
