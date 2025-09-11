import 'package:flutter/material.dart';
import '../services/history_store.dart';
import '../../widgets/nav.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('chemilens')),
      bottomNavigationBar: buildBottomNav(context, 0), // 履歴タブ選択
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 白背景側の見出しヘッダー
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                '最近の履歴',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize:
                      (theme.textTheme.titleMedium?.fontSize ?? 16) + 3, // +3pt
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Divider(height: 1),

            // 履歴リスト本体
            Expanded(
              child: ValueListenableBuilder<List<HistoryItem>>(
                valueListenable: HistoryStore.items,
                builder: (_, list, __) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'まだ履歴がありません',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final item = list[i];
                      final top = item.topMolecule;
                      return ListTile(
                        leading: (item.imageFile != null)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  item.imageFile!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.image),
                        title: Text(item.objectName),
                        subtitle: (top == null)
                            ? const Text('最有力分子：—')
                            : Text(
                                '最有力分子：${top.nameJp} / ${top.nameEn}（${top.formula}）'
                                '  •  ${(top.confidence * 100).toStringAsFixed(0)}%',
                              ),
                        // trailing の日時表示は削除
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
