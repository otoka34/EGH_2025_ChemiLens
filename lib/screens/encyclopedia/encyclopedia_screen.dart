import 'package:flutter/material.dart' hide Element;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_25_app/models/element.dart';
import 'package:team_25_app/screens/encyclopedia/widgets/element_grid.dart';
import 'package:team_25_app/services/encyclopedia_service.dart';
import 'package:team_25_app/widgets/common_bottom_navigation_bar.dart';

import '/widgets/common_app_bar.dart';

class EncyclopediaScreen extends ConsumerStatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  ConsumerState<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends ConsumerState<EncyclopediaScreen> {
  bool _showCompleteOverlay = false;

  void _checkCompletion(List<Element> elements) {
    final allDiscovered = elements.every((element) => element.discovered);
    if (allDiscovered && !_showCompleteOverlay) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showCompleteOverlay = true;
          });
        }
      });
    }
  }

  void _closeCompleteOverlay() {
    setState(() {
      _showCompleteOverlay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final encyclopediaState = ref.watch(encyclopediaServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Listen for changes to check for completion
    ref.listen<AsyncValue<List<Element>>>(encyclopediaServiceProvider, (_, next) {
      next.whenData((elements) {
        _checkCompletion(elements);
      });
    });

    return encyclopediaState.when(
      data: (elements) => _buildContent(context, elements, colorScheme),
      loading: () => Scaffold(
        extendBody: true,
        appBar: const CommonAppBar(),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const CommonBottomNavigationBar(currentIndex: 3),
      ),
      error: (error, stack) => Scaffold(
        extendBody: true,
        appBar: const CommonAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラーが発生しました: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(encyclopediaServiceProvider),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const CommonBottomNavigationBar(currentIndex: 3),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Element> elements,
    ColorScheme colorScheme,
  ) {
    final discoveredCount = elements.where((e) => e.discovered).length;
    final totalElements = elements.length;
    final completionRate = totalElements > 0
        ? (discoveredCount / totalElements * 100).round()
        : 0;

    return Scaffold(
      extendBody: true,
      appBar: const CommonAppBar(),
      body: Stack(
        children: [
          Container(
            color: const Color.fromARGB(255, 253, 249, 251),
            child: SafeArea(
              bottom: false,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // 新しいタイトル位置
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                      child: Text(
                        '元素ずかん',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ),
                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$discoveredCount / $totalElements',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 200,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9ECEF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: totalElements > 0
                                      ? discoveredCount / totalElements
                                      : 0.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          colorScheme.primary,
                                          const Color(0xFFE3579D),
                                        ], // プライマリカラーに変更
                                      ),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Bingo Grid (ElementGridを使用)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: SizedBox(
                      height:
                          MediaQuery.of(context).size.height * 0.5, // 画面高さの50%
                      child: ElementGrid(
                        elements: elements,
                        onElementTap: (_) {}, // タップしても何もしない
                      ),
                    ),
                  ),
                  // Stats
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 15.0),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            context,
                            '$discoveredCount',
                            '発見済み',
                            colorScheme.primary,
                          ),
                          _buildStatItem(
                            context,
                            '$completionRate%',
                            '達成率',
                            colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Legend
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(context, '発見済み', colorScheme.primary),
                        const SizedBox(width: 20),
                        _buildLegendItem(
                          context,
                          '未発見',
                          const Color(0xFFBDBDBD),
                        ),
                      ],
                    ),
                  ),
                  // BottomNavigationBar分の余白
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // Complete Overlay
          if (_showCompleteOverlay)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeCompleteOverlay,
                child: Container(
                  color: const Color(0xCC000000),
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(40.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 20),
                            const Text(
                              '図鑑コンプリート！',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'おめでとうございます！\n全ての元素を発見しました！',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _closeCompleteOverlay,
                              style:
                                  ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                  ).copyWith(
                                    overlayColor: MaterialStateProperty.all(
                                      Colors.transparent,
                                    ),
                                    elevation: MaterialStateProperty.all(0),
                                  ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [colorScheme.primary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 100,
                                    minHeight: 50,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '続ける',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavigationBar(
        currentIndex: 3, // 図鑑画面のインデックス
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String number,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          number,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: const Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: const Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}
