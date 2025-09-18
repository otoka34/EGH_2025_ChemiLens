import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:team_25_app/models/element.dart' as my_element;
import 'package:team_25_app/screens/encyclopedia/widgets/element_grid.dart';
import 'package:team_25_app/data/element_data.dart';
import 'package:team_25_app/widgets/app_bottom_navigation_bar.dart'; // <-- 追加

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  // ホーム画面用のダミー元素データ (ElementDataから取得)
  final List<my_element.Element> _homeElements = ElementData.allElements;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    final bottomNavBarHeight = 80.0; // AppBottomNavigationBarの高さ

    final availableHeight = screenHeight - appBarHeight - statusBarHeight - bottomNavBarHeight;
    final gridHeight = availableHeight * (1 / 2); 

    return Scaffold(
      extendBody: true, // <-- 追加: bodyがbottomNavigationBarの領域まで広がるようにする
      appBar: AppBar(
        title: GestureDetector( // <-- GestureDetectorで囲む
          onTap: () {
            context.go('/'); // ホーム画面へ遷移
          },
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/images/app_bar_icon.svg',
                height: 32,
                width: 32,
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // ホーム画面のタイトル
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              '元素ずかん',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
          ),
          // 元素図鑑のカード部分 (ボタンとして機能)
          GestureDetector(
            onTap: () {
              context.go('/encyclopedia');
            },
            child: AbsorbPointer(
              child: SizedBox(
                height: gridHeight,
                child: ElementGrid(
                  elements: _homeElements,
                  onElementTap: (index) {
                    // ホーム画面では個別のタップイベントは処理しない
                  },
                  childAspectRatio: 1.3, // <-- ホーム画面用の値を設定
                ),
              ),
            ),
          ),
          // 最近見た分子を見るボタン
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () {
                context.go('/history'); // 履歴画面へ遷移
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: const Text('最近見た分子を見る'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0), // <-- 追加
    );
  }
}
