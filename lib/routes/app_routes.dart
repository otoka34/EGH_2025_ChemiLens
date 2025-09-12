import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/collection/history_screen.dart';
import '../screens/camera/camera_screen.dart';
import '../screens/album/album_screen.dart';
import '../screens/result/result_screen.dart';
import '../models/detection_result.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // スプラッシュ画面
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    
    // ホーム画面（履歴画面）
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HistoryScreen(),
    ),
    
    // カメラ画面
    GoRoute(
      path: '/camera',
      name: 'camera',
      builder: (context, state) => const CameraScreen(),
    ),
    
    // アルバム画面
    GoRoute(
      path: '/album',
      name: 'album',
      builder: (context, state) => const AlbumScreen(),
    ),
    
    // 結果画面
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          return const Scaffold(
            body: Center(
              child: Text('Invalid parameters for result screen'),
            ),
          );
        }
        
        final imageFile = extra['imageFile'] as File?;
        final detection = extra['detection'] as DetectionResult?;
        
        if (imageFile == null || detection == null) {
          return const Scaffold(
            body: Center(
              child: Text('Missing required parameters'),
            ),
          );
        }
        
        return ResultScreen(
          imageFile: imageFile,
          detection: detection,
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