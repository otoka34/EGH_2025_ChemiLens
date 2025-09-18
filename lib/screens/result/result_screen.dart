import 'package:flutter/material.dart';
import 'package:team_25_app/models/detection_result.dart';

import 'widgets/compound_list.dart';
import 'widgets/image_display_widget.dart';
import 'widgets/object_info_widget.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text("認識結果")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImageDisplayWidget(imageFile: imageFile),
          ObjectInfoWidget(objectName: detection.objectName),
          const Divider(height: 1),
          CompoundList(compounds: detection.molecules),
        ],
      ),
    );
  }
}