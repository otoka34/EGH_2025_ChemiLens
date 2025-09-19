import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:team_25_app/models/compound.dart';
import 'package:team_25_app/services/api_service.dart';

class CompoundListItem extends StatelessWidget {
  final Compound compound;

  const CompoundListItem({super.key, required this.compound});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(compound.name),
      subtitle: Text(compound.description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: compound.cid.isEmpty
                ? null
                : () async {
                    // ローディングダイアログを表示
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    try {
                      // CIDからSDFデータを取得
                      final cidInt = int.tryParse(compound.cid);
                      if (cidInt == null) {
                        throw Exception('Invalid CID format');
                      }

                      final sdfData = await ApiService.getSdfDataByCid(cidInt);
                      
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
                            'moleculeName': compound.name,
                            'moleculeFormula': compound.description,
                          },
                        );
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('3Dモデルデータが見つかりませんでした'),
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
                          ),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('3Dで見る'),
          ),
        ],
      ),
    );
  }
}
