import 'package:flutter/material.dart';
import 'package:team_25_app/models/compound.dart';

import 'compound_list_item.dart';

class CompoundList extends StatelessWidget {
  final List<Compound> compounds;

  const CompoundList({super.key, required this.compounds});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: compounds.length,
        itemBuilder: (context, index) {
          return CompoundListItem(compound: compounds[index]);
        },
      ),
    );
  }
}
