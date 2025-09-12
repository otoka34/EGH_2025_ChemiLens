import 'package:flutter/material.dart';
import 'package:team_25_app/theme/app_colors.dart';

class HistoryTabBar extends StatelessWidget {
  final TabController tabController;

  const HistoryTabBar({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: tabController,
        indicatorColor: AppColors.primaryDark,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.primaryDark, // 選択時は紺色
        unselectedLabelColor: Colors.grey[600], // 未選択時は灰色
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'お気に入り'),
          Tab(text: 'すべて'),
        ],
      ),
    );
  }
}
