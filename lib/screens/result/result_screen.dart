import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/detection_result.dart';
import '../../models/molecule.dart';
import '../model_viewer/model_viewer_screen.dart';

class ResultScreen extends StatefulWidget {
  final dynamic imageFile; // File or String (blob URL for web)
  final DetectionResult detection;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.detection,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Map<int, bool> _isDescriptionVisible;

  @override
  void initState() {
    super.initState();
    _isDescriptionVisible = {
      for (var i = 0; i < widget.detection.molecules.length; i++) i: false
    };
  }

  @override
  Widget build(BuildContext context) {
    final List<Molecule> mols = widget.detection.molecules;

    return Scaffold(
      appBar: AppBar(title: const Text("認識結果")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          kIsWeb && widget.imageFile is String
              ? Image.network(widget.imageFile, height: 200, fit: BoxFit.cover)
              : Image.file(widget.imageFile as File, height: 200, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "物体: ${widget.detection.objectName}",
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
                final isVisible = _isDescriptionVisible[i] ?? false;

                return Column(
                  children: [
                    ListTile(
                      title: Text(m.name),
                      subtitle: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              m.description,
                              maxLines: isVisible ? null : 1, // 2行表示
                              overflow: isVisible ? TextOverflow.visible : TextOverflow.ellipsis,
                            ),
                          ),
                          // 固定幅のボタンコンテナ
                          SizedBox(
                            width: 60, // ボタンの幅を固定
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isDescriptionVisible[i] = !isVisible;
                                });
                              },
                              child: Text(
                                isVisible ? '閉じる' : 'もっと見る',
                                style: const TextStyle(color: Colors.blue, fontSize: 10),
                                textAlign: TextAlign.end, // 右寄せでボタンらしく見せる
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // AR Viewer Button
                          ElevatedButton(
                            onPressed: !hasSdf
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ModelViewerScreen(
                                          sdfData: m.sdf!,
                                          moleculeName: m.name,
                                          formula: m.formula,
                                        ),
                                      ),
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
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}