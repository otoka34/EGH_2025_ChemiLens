import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/detection_result.dart';
import '../../models/molecule.dart';
import '../molecule_viewer/molecule_viewer_screen.dart';
import '../model_viewer/simple_molecular_viewer_screen.dart';

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
              "物体: ${detection.objectName}",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: mols.length,
              itemBuilder: (context, i) {
                final m = mols[i];
                final hasSdf = m.sdf != null && m.sdf!.isNotEmpty;

                return ListTile(
                  title: Text(m.name),
                  subtitle: Text(m.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${(m.confidence * 100).toStringAsFixed(0)}%"),
                      const SizedBox(width: 8),
                      // 3D Viewer Button
                      IconButton(
                        icon: const Icon(Icons.threed_rotation),
                        tooltip: '3Dで見る',
                        onPressed: !hasSdf
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MoleculeViewerScreen(
                                      sdfData: m.sdf!,
                                      moleculeName: m.name,
                                    ),
                                  ),
                                );
                              },
                      ),
                      // AR Viewer Button (using SimpleMolecularViewerScreen for now)
                      IconButton(
                        icon: const Icon(Icons.view_in_ar),
                        tooltip: 'ARで見る',
                        onPressed: !hasSdf
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SimpleMolecularViewerScreen(
                                      sdfData: m.sdf!,
                                      moleculeName: m.name,
                                      formula: m.formula,
                                    ),
                                  ),
                                );
                              },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
