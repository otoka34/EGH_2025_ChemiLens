import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_25_app/screens/collection/widgets/history_list.dart';
import 'package:team_25_app/screens/collection/widgets/history_tab_bar.dart';
import 'package:team_25_app/services/history_filter_providers.dart';
import '/widgets/common_app_bar.dart';
import 'package:team_25_app/widgets/common_bottom_navigation_bar.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    final filter = _tabController.index == 0
        ? HistoryFilterType.favorites
        : HistoryFilterType.all;
    ref.read(historyFilterProvider.notifier).setFilter(filter);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(navigateToHistoryOnTap: false),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HistoryTabBar(tabController: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  HistoryList(targetFilter: HistoryFilterType.favorites),
                  HistoryList(targetFilter: HistoryFilterType.all),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(
        currentIndex: 0, // 履歴画面のインデックス
      ),
    );
  }
}
