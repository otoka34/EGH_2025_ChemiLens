import 'package:flutter/material.dart';
import '../widgets/nav.dart';
import 'camera/camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('chemilens')),
      bottomNavigationBar: buildBottomNav(context, 1), // 中央(Home)を選択状態
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // タイトル
              Text(
                '日常から分子を見つけよう',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              // フロー説明
              Text(
                '撮影orギャラリー  →  認識された物体名\n'
                '推定分子一覧 ＋ 分子の説明 ＋ 確信度を表示',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              // ← ご要望どおり、テキスト直下に start ボタン
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CameraScreen()),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('start'),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              // ここに「最近見た分子」などのカードを後で入れてもOK
              Expanded(
                child: Center(
                  child: Text(
                    '下のナビから「履歴」「検索」に移動できます。',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
