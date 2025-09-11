import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/detection_result.dart';
import '../../models/molecule.dart';

class ResultScreen extends StatelessWidget {
  final File imageFile;
  final DetectionResult detection;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.detection,
  });

  @override
  Widget build(BuildContext context) {
    final List<Molecule> mols = detection.molecules;

    return Scaffold(
      appBar: AppBar(title: const Text("認識結果")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.file(imageFile, height: 200, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "物体: ${detection.objectName}（${detection.objectCategory}）",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: mols.length,
              itemBuilder: (context, i) {
                final m = mols[i];
                return ListTile(
                  title: Text("${m.nameJp} / ${m.nameEn}  （${m.formula}）"),
                  subtitle: Text(m.description),
                  trailing: Text("${(m.confidence * 100).toStringAsFixed(0)}%"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
