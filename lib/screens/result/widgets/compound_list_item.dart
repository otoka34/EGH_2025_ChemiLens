import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:team_25_app/models/compound.dart';
import 'package:team_25_app/screens/result/widgets/compound_tile.dart';
import 'package:team_25_app/services/api_service.dart';
import 'package:team_25_app/services/image_compression_service.dart';
import 'package:team_25_app/widgets/common_loading.dart';

class CompoundListItem extends StatelessWidget {
  final Compound compound;
  final dynamic imageFile; // File, String, or XFile

  const CompoundListItem({
    super.key,
    required this.compound,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    return CompoundTile(
      name: compound.name,
      description: compound.description,
      trailing: ElevatedButton(
        onPressed: compound.cid.isEmpty ? null : () => _handle3DView(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: const Text('3Dで見る'),
      ),
    );
  }

  Future<void> _handle3DView(BuildContext context) async {
    // ローディングダイアログを表示
    CommonLoading.showLoadingDialog(context, message: '3Dモデルを読み込み中...');

    try {
      // CIDからSDFデータを取得
      final cidInt = int.tryParse(compound.cid);
      if (cidInt == null) {
        throw Exception('Invalid CID format');
      }

      final sdfData = await ApiService.getSdfDataByCid(cidInt);

      // ローディングダイアログを閉じる
      if (context.mounted) {
        CommonLoading.hideLoadingDialog(context);
      }

      if (sdfData != null && context.mounted) {
        String? originalImageUrl;
        if (imageFile is String) {
          // String型のURL（履歴からの遷移）
          originalImageUrl = imageFile as String;
        } else if (imageFile is XFile) {
          // XFile型の場合
          if (kIsWeb) {
            // Web環境ではXFile.pathがblob URLとして機能
            originalImageUrl = (imageFile as XFile).path;
          } else {
            // モバイル環境の場合、File変換してBase64エンコード
            try {
              final fileBytes = await File(
                (imageFile as XFile).path,
              ).readAsBytes();
              final compressedBytes =
                  await ImageCompressionService.compressImage(fileBytes);
              final base64Image = base64Encode(compressedBytes);
              originalImageUrl = 'data:image/jpeg;base64,$base64Image';
            } catch (e) {
              print('Error converting XFile to data URL: $e');
              originalImageUrl = null;
            }
          }
        } else if (imageFile is File) {
          // File型の場合、Uint8Listに変換してからBase64エンコード
          try {
            final fileBytes = await (imageFile as File).readAsBytes();
            final compressedBytes = await ImageCompressionService.compressImage(
              fileBytes,
            );
            final base64Image = base64Encode(compressedBytes);
            originalImageUrl = 'data:image/jpeg;base64,$base64Image';
          } catch (e) {
            print('Error converting file to data URL: $e');
            originalImageUrl = null;
          }
        } else {
          originalImageUrl = null;
        }

        // 3Dビューアー画面に遷移
        if (context.mounted) {
          context.pushNamed(
            'molecular_viewer',
            extra: {
              'sdfData': sdfData,
              'moleculeName': compound.name,
              'moleculeFormula': compound.formula,
              'originalImageUrl': originalImageUrl,
            },
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('3Dモデルデータが見つかりませんでした')));
        }
      }
    } catch (e) {
      // ローディングダイアログを閉じる
      if (context.mounted) {
        CommonLoading.hideLoadingDialog(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生しました: ${e.toString()}')));
      }
    }
  }
}
