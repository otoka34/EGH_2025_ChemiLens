import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:team_25_app/theme/app_colors.dart';

class CommonBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const CommonBottomNavigationBar({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/history');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/camera');
        break;
      case 3:
        context.go('/encyclopedia');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // final colorScheme = Theme.of(context).colorScheme; // 削除

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // フッター背景
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surface,
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
              // 履歴ボタン
              Expanded(
                child: _buildNavButton(
                  context: context,
                  index: 0,
                  selectedIcon: Icons.history,
                  unselectedIcon: Icons.history_outlined,
                  label: 'りれき',
                  isSelected: currentIndex == 0,
                ),
              ),
              // 検索ボタン
              Expanded(
                child: _buildNavButton(
                  context: context,
                  index: 1,
                  selectedIcon: Icons.search,
                  unselectedIcon: Icons.search_outlined,
                  label: 'けんさく',
                  isSelected: currentIndex == 1,
                ),
              ),
              // カメラボタン用の空きスペース
              const SizedBox(width: 80),
              // 図鑑ボタン
              Expanded(
                child: _buildNavButton(
                  context: context,
                  index: 3,
                  selectedIcon: Icons.menu_book,
                  unselectedIcon: Icons.menu_book_outlined,
                  label: 'ずかん',
                  isSelected: currentIndex == 3,
                ),
              ),
              // プロフィールボタン
              Expanded(
                child: _buildNavButton(
                  context: context,
                  index: 4,
                  selectedIcon: Icons.manage_accounts,
                  unselectedIcon: Icons.manage_accounts_outlined,
                  label: 'とうろく',
                  isSelected: currentIndex == 4,
                ),
              ),
            ],
          ),
        ),
        // カメラボタン（上にはみ出し）
        Positioned(
          top: -10,
          left: MediaQuery.of(context).size.width / 2 - 40,
          child: GestureDetector(
            onTap: () => _onTap(context, 2),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                shape: BoxShape.circle,
                boxShadow: const [
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
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
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
    required IconData selectedIcon,
    required IconData unselectedIcon,
    required String label,
    required bool isSelected,
  }) {
    final color = isSelected ? AppColors.primary : AppColors.primaryDark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTap(context, index),
        child: SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : unselectedIcon,
                size: 24,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
