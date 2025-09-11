import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


import '../../models/detection_result.dart';
import '../../services/api_service.dart';
import '../services/history_store.dart';
import '../../widgets/nav.dart';
import '../result/result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isLoading = false;

  Future<void> _pickFrom(ImageSource source) async {
    if (_isLoading) return;

    final picker = ImagePicker();
    XFile? picked;

    try {
      picked = await picker.pickImage(
        source: source,
        imageQuality: 80, // 軽量化
        maxWidth: 1024,
        maxHeight: 1024,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('画像取得に失敗: $e')));
      return;
    }

    if (picked == null) {
      // キャンセル
      return;
    }

    await _processPicked(picked);
  }

  Future<void> _processPicked(XFile picked) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final file = File(picked.path);

      // 元画像のバイトデータを直接読み込む
      final Uint8List imageBytes = await picked.readAsBytes();

      // バックエンドへ解析リクエスト（元画像のバイト列とMIMEタイプ）
      final DetectionResult result = await ApiService.analyzeImage(
        imageBytes,
        picked.mimeType,
      );

      // 履歴へ追加
      HistoryStore.add(
        HistoryItem(
          objectName: result.objectName,
          viewedAt: DateTime.now(),
          molecules: result.molecules,
          imageFile: file,
        ),
      );

      if (!mounted) return;
      // 結果画面へ
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(imageFile: file, detection: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('解析に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 両ボタン共通のスタイル（枠線/角丸/サイズ/色を完全一致）
    final borderSide = BorderSide(color: theme.colorScheme.outline, width: 1);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final ButtonStyle buttonStyle = OutlinedButton.styleFrom(
      shape: shape,
      side: borderSide,
      minimumSize: const Size.fromHeight(52), // 高さ統一
      padding: const EdgeInsets.symmetric(horizontal: 16),
      foregroundColor: theme.colorScheme.onSurface,
      backgroundColor: Colors.transparent, // 内部色を合わせる
    );

    return Scaffold(
      appBar: AppBar(title: const Text('chemilens')),
      // Homeをタップしたら必ずHomeへ戻る（常に遷移）
      bottomNavigationBar: buildBottomNav(context, 1, alwaysNavigate: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [CircularProgressIndicator(), SizedBox(height: 16)],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // カメラで撮影する（ギャラリーと完全同一のOutlinedButton）
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: buttonStyle,
                        onPressed: () => _pickFrom(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('カメラで撮影する'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ギャラリーから選ぶ
                    SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                        style: buttonStyle,
                        onPressed: () => _pickFrom(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('ギャラリーから選ぶ'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
