import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/detection_result.dart';
import '../screens/camera/camera_screen.dart';
import '../screens/collection/history_screen.dart';
import '../screens/detail/detail_screen.dart';
import '../screens/encyclopedia/encyclopedia_screen.dart';
import '../screens/model_viewer/model_viewer_screen.dart';
import '../screens/result/result_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/splash/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // スプラッシュ画面
    GoRoute(
      path: '/splash',
      name: 'splash',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
      },
    ),

    // 履歴画面
    GoRoute(
      path: '/history',
      name: 'history',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const HistoryScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
      },
    ),

    // 元素図鑑画面
    GoRoute(
      path: '/encyclopedia',
      name: 'encyclopedia',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const EncyclopediaScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
      },
    ),

    // カメラ画面
    GoRoute(
      path: '/camera',
      name: 'camera',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const CameraScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
      },
    ),

    // 詳細画面
    GoRoute(
      path: '/detail/:historyId',
      pageBuilder: (context, state) {
        final historyId = state.pathParameters['historyId'];

        Widget child;
        if (historyId == null) {
          child = const Scaffold(
            appBar: null,
            body: Center(child: Text('無効なパラメータです')),
          );
        } else {
          child = DetailScreen(historyId: historyId);
        }

        return CustomTransitionPage(
          key: state.pageKey,
          child: child,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
      },
    ),

    // 結果画面
    GoRoute(
      path: '/result',
      name: 'result',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;

        Widget child;
        if (extra == null) {
          child = const Scaffold(
            body: Center(child: Text('Invalid parameters for result screen')),
          );
        } else {
          final imageFile = extra['imageFile'] as File?;
          final detection = extra['detection'] as DetectionResult?;

          if (imageFile == null || detection == null) {
            child = const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            );
          } else {
            child = ResultScreen(imageFile: imageFile, detection: detection);
          }
        }

        return CustomTransitionPage(
          key: state.pageKey,
          child: child,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
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

    // 3D分子ビューアー画面
    GoRoute(
      path: '/molecular_viewer',
      name: 'molecular_viewer',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;

        Widget child;
        if (extra == null) {
          child = const Scaffold(body: Center(child: Text('分子データが指定されていません')));
        } else {
          final sdfData = extra['sdfData'] as String?;
          final moleculeName = extra['moleculeName'] as String?;
          final moleculeFormula = extra['moleculeFormula'] as String?;
          final originalImageUrl = extra['originalImageUrl'] as String?;

          if (sdfData == null) {
            child = const Scaffold(body: Center(child: Text('SDFデータが見つかりません')));
          } else {
            child = ModelViewerScreen(
              sdfData: sdfData,
              moleculeName: moleculeName ?? '不明な化合物',
              formula: moleculeFormula,
              originalImageUrl: originalImageUrl,
            );
          }
        }

        return CustomTransitionPage(
          key: state.pageKey,
          child: child,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
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
            onPressed: () => context.go('/history'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
