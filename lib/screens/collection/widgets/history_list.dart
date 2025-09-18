import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_25_app/screens/collection/widgets/history_date_header.dart';
import 'package:team_25_app/screens/collection/widgets/history_item_widget.dart';
import 'package:team_25_app/services/history_filter_providers.dart';

class HistoryList extends ConsumerWidget {
  final HistoryFilterType targetFilter;

  const HistoryList({super.key, required this.targetFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // フィルターを設定（mountedチェック付き）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        ref.read(historyFilterProvider.notifier).setFilter(targetFilter);
      }
    });

    final groupedHistoriesAsync = ref.watch(groupedHistoriesProvider);

    if (groupedHistoriesAsync.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedHistoriesAsync.length,
      itemBuilder: (context, groupIndex) {
        final entry = groupedHistoriesAsync.entries.elementAt(groupIndex);
        final dateLabel = entry.key;
        final items = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日付ヘッダー
            HistoryDateHeader(dateLabel: dateLabel),

            // その日のアイテム一覧
            ...items.map((item) {
              return HistoryItemWidget(item: item);
            }),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        targetFilter == HistoryFilterType.favorites
            ? 'お気に入りがありません'
            : 'まだ履歴がありません',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
