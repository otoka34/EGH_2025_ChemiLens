import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:team_25_app/models/compound.dart';
import 'package:team_25_app/models/history_item.dart';
import 'package:team_25_app/services/history_service.dart';
import 'package:team_25_app/theme/app_colors.dart';

class HistoryItemWidget extends ConsumerWidget {
  final HistoryItem item;

  const HistoryItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final topThreeCompounds = item.compounds.take(3).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タップ可能なメインエリア（画像とコンテンツ）
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // 詳細画面へ遷移
                      context.push('/detail/${item.id}');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 撮影画像
                          _buildImage(),
                          const SizedBox(width: 12),
                          // コンテンツ部分
                          Expanded(
                            child: _buildContent(theme, topThreeCompounds),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // お気に入りアイコン（独立してタップ可能）
              _buildFavoriteIcon(ref),
            ],
          ),

          // 境界線
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Divider(height: 1, color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return SizedBox(
      width: 80,
      height: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: item.imageUrl.isNotEmpty
            ? Image.network(item.imageUrl, fit: BoxFit.cover)
            : Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 40, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, List<Compound> topThreeCompounds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 物体名（太字タイトル）
        Text(
          item.objectName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),

        // 成分3つ
        if (topThreeCompounds.isNotEmpty) ...[
          ...topThreeCompounds.map(
            (compound) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                compound.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFavoriteIcon(WidgetRef ref) {
    return GestureDetector(
      onTap: () =>
          ref.read(historyServiceProvider.notifier).toggleFavorite(item.id),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          item.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: item.isFavorite ? AppColors.textSecondary : Colors.grey,
          size: 24,
        ),
      ),
    );
  }
}
