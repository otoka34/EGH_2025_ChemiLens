import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:team_25_app/models/compound.dart';
import 'package:team_25_app/models/history_item.dart';
import 'package:team_25_app/services/history_service.dart';
import 'package:team_25_app/services/api_service.dart';
import 'package:team_25_app/theme/app_colors.dart';

class DetailScreen extends ConsumerWidget {
  final String historyId;

  const DetailScreen({super.key, required this.historyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyServiceProvider);

    return historyAsync.when(
      data: (histories) {
        final item = histories.firstWhere(
          (h) => h.id == historyId,
          orElse: () => throw Exception('History not found'),
        );
        return _buildDetailContent(context, item);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('エラー')),
        body: Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, HistoryItem item) {
    return Scaffold(
      appBar: AppBar(title: Text(item.objectName)),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 撮影画像表示部分
            _buildImageSection(item),

            // オブジェクト情報セクション
            _buildObjectInfoSection(context, item),

            // 分子リストセクション
            _buildMoleculeListSection(context, item.compounds),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(HistoryItem item) {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          item.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.background,
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  size: 64,
                  color: AppColors.primaryDark.withValues(alpha: 0.5),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildObjectInfoSection(BuildContext context, HistoryItem item) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'オブジェクト情報',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('物体名', item.objectName),
          // カテゴリ情報は新しいモデルにはない
          const SizedBox(height: 8),
          _buildInfoRow('撮影日時', _formatDateTime(item.createdAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoleculeListSection(
    BuildContext context,
    List<Compound> molecules,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '検出された化合物',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          ...molecules.map((molecule) => _buildMoleculeCard(context, molecule)),
        ],
      ),
    );
  }

  Widget _buildMoleculeCard(BuildContext context, Compound molecule) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左側：分子情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    molecule.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    molecule.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 右側：ARボタン
            SizedBox(width: 80, child: _buildARButton(context, molecule)),
          ],
        ),
      ),
    );
  }

  Widget _buildARButton(BuildContext context, Compound molecule) {
    return OutlinedButton(
      onPressed: () async {
        // ローディングダイアログを表示
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          String? sdfData;
          
          // CIDからSDFデータを取得
          if (molecule.cid.isNotEmpty) {
            final cidInt = int.tryParse(molecule.cid);
            if (cidInt != null) {
              sdfData = await ApiService.getSdfDataByCid(cidInt);
            }
          }
          
          // ローディングダイアログを閉じる
          if (context.mounted) {
            Navigator.of(context).pop();
          }

          if (sdfData != null && context.mounted) {
            // 3Dビューアー画面に遷移
            context.pushNamed(
              'molecular_viewer',
              extra: {
                'sdfData': sdfData,
                'moleculeName': molecule.name,
                'moleculeFormula': molecule.description,
              },
            );
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${molecule.name}の3Dモデルデータが見つかりませんでした'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        } catch (e) {
          // ローディングダイアログを閉じる
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('エラーが発生しました: ${e.toString()}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      style: FilledButton.styleFrom(
        foregroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.primary),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text('3Dで見る', style: TextStyle(fontSize: 10))],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
