import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/camera');
        break;
      case 2:
        context.go('/search');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // フッター背景
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(0, -2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              // ホームボタン（左半分を占有）
              Expanded(
                child: _buildNavButton(
                  context: context,
                  index: 0,
                  icon: Icons.home,
                  label: 'ホーム',
                  isSelected: currentIndex == 0,
                ),
              ),
              // カメラボタン用の空きスペース
              const SizedBox(width: 80),
              // 検索ボタン（右半分を占有）
              Expanded(
                child: _buildNavButton(
                  context: context,
                  index: 2,
                  icon: Icons.search,
                  label: '検索',
                  isSelected: currentIndex == 2,
                ),
              ),
            ],
          ),
        ),
        // カメラボタン（上にはみ出し）
        Positioned(
          top: -20,
          left: MediaQuery.of(context).size.width / 2 - 40,
          child: GestureDetector(
            onTap: () => _onTap(context, 1),
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.lightBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/camera_icon.svg',
                  width: 40,
                  height: 40,
                  colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTap(context, index),
        child: Container(
          height: 80,
          child: Center(
            child: Icon(
              icon,
              size: 40,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}