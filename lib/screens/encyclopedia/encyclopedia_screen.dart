import 'package:flutter/material.dart' hide Element;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:team_25_app/models/element.dart';
import 'package:team_25_app/screens/encyclopedia/widgets/element_grid.dart';
import 'package:team_25_app/data/element_data.dart'; // ElementDataをインポート

class EncyclopediaScreen extends StatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  State<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends State<EncyclopediaScreen> {
  // ダミーデータ (Elementモデルを使用)
  // ElementDataから取得するように変更
  List<Element> _elements = []; // 初期化を空リストに変更

  @override
  void initState() {
    super.initState();
    _elements = List.from(ElementData.allElements); // ElementDataからコピーして初期化
  }

  bool _showCompleteOverlay = false;

  void _toggleElementDiscovered(int index) {
    setState(() {
      _elements[index] = _elements[index].copyWith(discovered: !_elements[index].discovered);
      _checkCompletion();
    });
  }

  void _checkCompletion() {
    final allDiscovered = _elements.every((element) => element.discovered);
    if (allDiscovered) {
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _showCompleteOverlay = true;
        });
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
    final discoveredCount = _elements.where((e) => e.discovered).length;
    final totalElements = _elements.length;
    final completionRate = (discoveredCount / totalElements * 100).round();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
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
      body: Stack(
        children: [
          Container(
            color: const Color.fromARGB(255, 253, 249, 251),
            child: SafeArea(
              child: Column(
                children: [
                  // 新しいタイトル位置
                  const Padding(
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
                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
                                  widthFactor: discoveredCount / totalElements,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [colorScheme.primary, Color(0xFFE3579D)], // プライマリカラーに変更
                                      ),
                                      borderRadius: const BorderRadius.all(Radius.circular(4)),
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
                  Expanded(
                    child: ElementGrid(
                      elements: _elements, // ElementDataから取得したリストを使用
                      onElementTap: (index) => _toggleElementDiscovered(index),
                    ),
                  ),
                  // Stats
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      padding: const EdgeInsets.all(15.0),
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
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(
                            context, '発見済み', colorScheme.primary),
                        const SizedBox(width: 20),
                        _buildLegendItem(
                            context, '未発見', const Color(0xFFBDBDBD)),
                      ],
                    ),
                  ),
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
                            const Text(
                              '🎉',
                              style: TextStyle(fontSize: 64),
                            ),
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
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ).copyWith(
                                overlayColor: MaterialStateProperty.all(Colors.transparent),
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
                                  constraints: const BoxConstraints(minWidth: 100, minHeight: 50),
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
    );
  }

  Widget _buildStatItem(
      BuildContext context, String number, String label, Color color) {
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