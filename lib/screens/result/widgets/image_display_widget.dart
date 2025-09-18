import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageDisplayWidget extends StatelessWidget {
  final dynamic imageFile; // XFile, File, or String (blob URL for web)

  const ImageDisplayWidget({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web環境では XFile か String を想定
      if (imageFile is XFile) {
        return Image.network(
          imageFile.path,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: Text('画像の読み込みに失敗しました')),
            );
          },
        );
      } else if (imageFile is String) {
        return Image.network(
          imageFile,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    } else {
      // モバイル環境では File
      if (imageFile is XFile) {
        return Image.file(
          File(imageFile.path),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else if (imageFile is File) {
        return Image.file(
          imageFile,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }

    // フォールバック
    return Container(
      height: 200,
      color: Colors.grey[300],
      child: const Center(child: Text('画像を表示できません')),
    );
  }
}
