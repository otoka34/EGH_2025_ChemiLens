import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraFloatingActionButtons extends StatelessWidget {
  final bool isLoading;
  final Function(ImageSource) onPickImage;

  const CameraFloatingActionButtons({
    super.key,
    required this.isLoading,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CircularProgressIndicator();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // アルバム選択用FAB
        FloatingActionButton(
          heroTag: "album",
          onPressed: () => onPickImage(ImageSource.gallery),
          child: const Icon(Icons.photo_library),
        ),
        const SizedBox(height: 12),
        // カメラ撮影用FAB
        FloatingActionButton(
          heroTag: "camera",
          onPressed: () => onPickImage(ImageSource.camera),
          child: const Icon(Icons.camera_alt),
        ),
      ],
    );
  }
}
