import 'package:flutter/material.dart';
import 'package:team_25_app/models/detection_result.dart';

import 'widgets/compound_list.dart';
import 'widgets/image_display_widget.dart';
import 'widgets/object_info_widget.dart';
import '/theme/app_colors.dart';

class ResultScreen extends StatelessWidget {
  final dynamic imageFile; // File or String
  final DetectionResult detection;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.detection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "認識結果",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImageDisplayWidget(imageFile: imageFile),
          ObjectInfoWidget(objectName: detection.objectName),
          const Divider(height: 1),
          CompoundList(compounds: detection.molecules, imageFile: imageFile),
        ],
      ),
    );
  }
}
