import 'package:flutter/material.dart';
import '../../models/detection_result.dart';
import '../../models/molecule.dart';
import '../services/openai_service.dart';
import '../services/history_store.dart';
import '../../widgets/nav.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  DetectionResult? _result;
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty || _loading) return;

    FocusScope.of(context).unfocus(); // キーボードを閉じる

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final res = await OpenAIService.analyzeByObjectName(q);

      // 最有力（confidence最大）の分子を算出
      final Molecule? top = (res.molecules.isEmpty)
          ? null
          : res.molecules.reduce(
              (a, b) => a.confidence >= b.confidence ? a : b,
            );

      // 履歴に追加（画像なし）
      HistoryStore.add(
        HistoryItem(
          objectName: res.objectName,
          viewedAt: DateTime.now(),
          molecules: res.molecules,
          imageFile: null,
          topMolecule: top,
        ),
      );

      if (!mounted) return;
      setState(() => _result = res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('chemilens')),
      bottomNavigationBar: buildBottomNav(context, 2), // 検索タブ選択
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 入力フォーム
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: '例）ティッシュ箱 / コーヒー / レモン など',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _search,
                    icon: const Icon(Icons.search),
                    label: const Text('検索'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ステータス／結果
              if (_loading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ] else if (_error != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ),
              ] else if (_result != null) ...[
                // 物体名＋カテゴリ
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      '物体：${_result!.objectName}（${_result!.objectCategory}）',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 6),

                // 分子リスト（スクロール）
                Expanded(
                  child: ListView.separated(
                    itemCount: _result!.molecules.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final Molecule m = _result!.molecules[i];
                      return ListTile(
                        title: Text(
                          '${m.nameJp} / ${m.nameEn}  （${m.formula}）',
                        ),
                        subtitle: Text(m.description),
                        trailing: Text(
                          '${(m.confidence * 100).toStringAsFixed(0)}%',
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                // 初期表示（未検索）
                Expanded(
                  child: Center(
                    child: Text(
                      '日常の物体名を入力して検索してください',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
