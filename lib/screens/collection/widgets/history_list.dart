import 'package:flutter/material.dart';
import 'package:team_25_app/screens/collection/widgets/history_date_header.dart';
import 'package:team_25_app/screens/collection/widgets/history_item_widget.dart';
import 'package:team_25_app/screens/services/history_store.dart';

class HistoryList extends StatelessWidget {
  final HistoryFilter targetFilter;

  const HistoryList({super.key, required this.targetFilter});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<HistoryItem>>(
      valueListenable: HistoryStore.items,
      builder: (context, allItems, __) {
        final filteredItems = targetFilter == HistoryFilter.favorites
            ? allItems.where((item) => item.isFavorite).toList()
            : allItems;

        // 日時でグループ化
        final groupedItems = _groupItemsByDate(filteredItems);

        if (groupedItems.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: groupedItems.length,
          itemBuilder: (context, groupIndex) {
            final entry = groupedItems.entries.elementAt(groupIndex);
            final dateLabel = entry.key;
            final items = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 日付ヘッダー
                HistoryDateHeader(dateLabel: dateLabel),

                // その日のアイテム一覧
                ...items.map((item) {
                  final originalIndex = allItems.indexOf(item);
                  return HistoryItemWidget(
                    item: item,
                    originalIndex: originalIndex,
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Map<String, List<HistoryItem>> _groupItemsByDate(List<HistoryItem> items) {
    final grouped = <String, List<HistoryItem>>{};

    for (final item in items) {
      final dateKey = _formatDateKey(item.viewedAt);
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }

    return grouped;
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return '今日';
    } else if (itemDate == today.subtract(const Duration(days: 1))) {
      return '昨日';
    } else {
      return '${date.year}.${date.month}.${date.day}';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        targetFilter == HistoryFilter.favorites ? 'お気に入りがありません' : 'まだ履歴がありません',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
