import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/detection_result.dart';
import '../../models/molecule.dart';
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
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (m.formula != null && m.formula!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        m.formula!,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    m.description,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  "${(m.confidence * 100).toStringAsFixed(0)}%",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: (m.sdf == null || m.sdf!.isEmpty)
                                      ? null
                                      : () async {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (BuildContext context) {
                                              return const Center(child: CircularProgressIndicator());
                                            },
                                          );

                                          try {
                                            // SDFデータをそのまま使用して3D表示画面へ
                                            if (!context.mounted) return;
                                            Navigator.pop(context);

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
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('3Dモデルの表示に失敗しました: $e')),
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('ARで表示'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
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
