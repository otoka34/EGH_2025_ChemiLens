import 'package:flutter/material.dart';
import 'package:team_25_app/models/compound.dart';

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
                : () {
                    // TODO: cid から sdfData を取得する実装が必要
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('3D表示機能は準備中です')),
                    );
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
