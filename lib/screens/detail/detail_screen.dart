import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:team_25_app/models/compound.dart';
import 'package:team_25_app/models/history_item.dart';
import 'package:team_25_app/screens/detail/widgets/image_card.dart';
import 'package:team_25_app/screens/detail/widgets/info_section_card.dart';
import 'package:team_25_app/screens/detail/widgets/molecule_card.dart';
import 'package:team_25_app/services/api_service.dart';
import 'package:team_25_app/services/history_service.dart';
import 'package:team_25_app/theme/app_colors.dart';
import 'package:team_25_app/theme/text_styles.dart';
import 'package:team_25_app/widgets/common_loading.dart';

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
          Scaffold(body: CommonLoading.fullScreen(message: '読み込み中...')),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'エラー',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.primaryDark,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, HistoryItem item) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          item.objectName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
            _buildMoleculeListSection(context, item.compounds, item),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(HistoryItem item) {
    return ImageCard(imageUrl: item.imageUrl, height: 300);
  }

  Widget _buildObjectInfoSection(BuildContext context, HistoryItem item) {
    return InfoSectionCard(
      title: 'オブジェクト情報',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _buildInfoRow('物体名', item.objectName),
          const SizedBox(height: 12),
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
          child: Text(label, style: TextStyleContext.infoLabel),
        ),
        Expanded(child: Text(value, style: TextStyleContext.infoValue)),
      ],
    );
  }

  Widget _buildMoleculeListSection(
    BuildContext context,
    List<Compound> molecules,
    HistoryItem item,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('検出された化合物', style: TextStyleContext.sectionTitle),
        ),
        ...molecules.map(
          (molecule) => _buildMoleculeCard(context, molecule, item),
        ),
      ],
    );
  }

  Widget _buildMoleculeCard(
    BuildContext context,
    Compound molecule,
    HistoryItem item,
  ) {
    return MoleculeCard(
      name: molecule.name,
      description: molecule.description,
      actionButton: _buildARButton(context, molecule, item),
    );
  }

  Widget _buildARButton(
    BuildContext context,
    Compound molecule,
    HistoryItem item,
  ) {
    return ElevatedButton( // Changed from OutlinedButton
      onPressed: molecule.cid.isEmpty ? null : () async {
        // ローディングダイアログを表示
        CommonLoading.showLoadingDialog(context, message: '3Dモデルを読み込み中...');

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
            CommonLoading.hideLoadingDialog(context);
          }

          if (sdfData != null && context.mounted) {
            // 3Dビューアー画面に遷移
            context.pushNamed(
              'molecular_viewer',
              extra: {
                'sdfData': sdfData,
                'moleculeName': molecule.name,
                'moleculeFormula': molecule.formula,
                'originalImageUrl': item.imageUrl,
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
            CommonLoading.hideLoadingDialog(context);
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
      style: ElevatedButton.styleFrom( // Changed from FilledButton.styleFrom
        backgroundColor: Theme.of(context).colorScheme.primary, // Matched
        foregroundColor: Theme.of(context).colorScheme.onPrimary, // Matched
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Matched
      ),
      child: const Text('3Dで見る'), // Changed from Column with Text and fontSize
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
