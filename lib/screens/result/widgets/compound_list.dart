import 'package:flutter/material.dart';
import 'package:team_25_app/models/compound.dart';

import 'compound_list_item.dart';

class CompoundList extends StatelessWidget {
  final List<Compound> compounds;
  final dynamic imageFile; // File or String

  const CompoundList({
    super.key,
    required this.compounds,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: compounds.length,
        itemBuilder: (context, index) {
          return CompoundListItem(
            compound: compounds[index],
            imageFile: imageFile,
          );
        },
      ),
    );
  }
}
