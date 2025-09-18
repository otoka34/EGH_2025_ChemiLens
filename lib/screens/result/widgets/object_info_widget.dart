import 'package:flutter/material.dart';

class ObjectInfoWidget extends StatelessWidget {
  final String objectName;

  const ObjectInfoWidget({super.key, required this.objectName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        "物体: $objectName",
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
