import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:team_25_app/models/history_item.dart';

import 'history_service.dart';

part 'history_filter_providers.g.dart';

enum HistoryFilterType { all, favorites }

// お気に入りフィルター用のプロバイダー
@riverpod
class HistoryFilter extends _$HistoryFilter {
  @override
  HistoryFilterType build() => HistoryFilterType.all;

  void setFilter(HistoryFilterType filter) {
    state = filter;
  }
}

// フィルター済み履歴リストプロバイダー
@riverpod
List<HistoryItem> filteredHistories(ref) {
  final histories = ref.watch(historyServiceProvider).value ?? <HistoryItem>[];
  final filter = ref.watch(historyFilterProvider);

  switch (filter) {
    case HistoryFilterType.favorites:
      return histories.where((HistoryItem h) => h.isFavorite).toList();
    case HistoryFilterType.all:
    default:
      return List<HistoryItem>.from(histories);
  }
}

// 日付グループ化履歴プロバイダー
@riverpod
Map<String, List<HistoryItem>> groupedHistories(ref) {
  final histories = ref.watch(filteredHistoriesProvider);
  final grouped = <String, List<HistoryItem>>{};

  for (final history in histories) {
    final dateKey = _formatDateKey(history.createdAt);
    grouped.putIfAbsent(dateKey, () => []).add(history);
  }

  return grouped;
}

/// 日付キーをフォーマット
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
