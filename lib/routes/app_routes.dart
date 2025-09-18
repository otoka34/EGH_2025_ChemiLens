import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/detection_result.dart';
import '../screens/collection/history_screen.dart';
import '../screens/detail/detail_screen.dart';
import '../screens/result/result_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/ar_viewer/ar_viewer_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/encyclopedia/encyclopedia_screen.dart'; // <-- 追加

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // スプラッシュ画面
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // ホーム画面
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => HomeScreen(),
    ),

    // 履歴画面
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (context, state) => const HistoryScreen(),
    ),

    // 元素図鑑画面 <-- 追加
    GoRoute(
      path: '/encyclopedia',
      name: 'encyclopedia',
      builder: (context, state) => const EncyclopediaScreen(),
    ),

    // 詳細画面
    GoRoute(
      path: '/detail/:historyId',
      builder: (context, state) {
        final historyId = state.pathParameters['historyId'];
        
        if (historyId == null) {
          return const Scaffold(
            appBar: null,
            body: Center(child: Text('無効なパラメータです')),
          );
        }

        return DetailScreen(historyId: historyId);
      },
    ),

    // 結果画面
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          return const Scaffold(
            body: Center(child: Text('Invalid parameters for result screen')),
          );
        }

        final imageFile = extra['imageFile'] as File?;
        final detection = extra['detection'] as DetectionResult?;

        if (imageFile == null || detection == null) {
          return const Scaffold(
            body: Center(child: Text('Missing required parameters')),
          );
        }

        return ResultScreen(imageFile: imageFile, detection: detection);
      },
    ),

    // AR Viewer画面
    GoRoute(
      path: '/ar_viewer',
      name: 'ar_viewer',
      builder: (context, state) {
        final glbModelUrl = state.extra as String?;
        if (glbModelUrl == null) {
          return const Scaffold(
            body: Center(child: Text('3DモデルのURLが指定されていません')),
          );
        }
        return ARViewerScreen(glbModelUrl: glbModelUrl);
      },
    ),

    // 検索画面
    GoRoute(
      path: '/search',
      name: 'search',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const SearchScreen(),
          transitionDuration: Duration.zero, // アニメーションなし
          reverseTransitionDuration: Duration.zero, // 戻る時のアニメーションもなし
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child; // そのまま表示
          },
        );
      },
    ),
  ],

  // エラーハンドリング
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Page not found: ${state.matchedLocation}',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
