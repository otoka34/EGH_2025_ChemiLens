import 'package:flutter/material.dart';

class HistoryTabBar extends StatelessWidget {
  final TabController tabController;

  const HistoryTabBar({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: tabController,
        indicatorColor: const Color(0xFF0F1A2B), // 紺色の下線
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF0F1A2B), // 選択時は紺色
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
