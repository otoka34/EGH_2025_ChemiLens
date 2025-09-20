import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:team_25_app/services/api_service.dart';
import 'package:team_25_app/widgets/common_loading.dart';

import '/theme/app_colors.dart';

class ModelViewerScreen extends StatefulWidget {
  final String sdfData;
  final String moleculeName;
  final String? formula;
  final String? originalImageUrl; // 元の画像URL（base64またはネットワークURL）

  const ModelViewerScreen({
    super.key,
    required this.sdfData,
    required this.moleculeName,
    this.formula,
    this.originalImageUrl,
  });

  @override
  State<ModelViewerScreen> createState() => _ModelViewerScreenState();
}

class _ModelViewerScreenState extends State<ModelViewerScreen> {
  String? _glbUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      print(
        'ModelViewerScreen: Converting SDF to GLB (${widget.sdfData.length} chars)',
      );

      // SDFデータをGLBに変換
      final glbData = await ApiService.convertSdfToGlb(widget.sdfData);
      print(
        'ModelViewerScreen: GLB conversion completed (${glbData.length} bytes)',
      );

      if (kIsWeb) {
        // Web環境では単純にBase64文字列を使用
        final base64String = Uri.dataFromBytes(
          glbData,
          mimeType: 'model/gltf-binary',
        ).toString();

        print(
          'ModelViewerScreen: Base64 Data URL ready (${base64String.length} chars)',
        );

        if (mounted) {
          setState(() {
            _glbUrl = base64String;
            _isLoading = false;
          });
        }
      } else {
        // モバイル環境では一時ファイルに保存
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/molecule_${DateTime.now().millisecondsSinceEpoch}.glb',
        );
        await file.writeAsBytes(glbData);

        if (mounted) {
          setState(() {
            _glbUrl = file.path;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // print(
// print(
// print(
// print('ModelViewerScreen: Error loading model: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('3Dモデルの読み込みに失敗しました: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.moleculeName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? CommonLoading.fullScreen(message: '3Dモデルを読み込み中...')
          : _glbUrl == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('3Dモデルの読み込みに失敗しました'),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // 3Dモデル（背景）
                      ModelViewer(
                        src: _glbUrl!,
                        alt: '${widget.moleculeName}の3Dモデル',
                        ar: false, // ARは使用せず、通常の3D表示のみ
                        autoRotate: true,
                        cameraControls: true,
                        backgroundColor: const Color(0xFFE0E0E0),
                        loading: Loading.lazy,
                        touchAction: TouchAction.panY,
                        debugLogging: false, // デバッグログを無効化
                        // ズーム感度を改善
                        minCameraOrbit: "auto auto 5%", // 最小距離を近くに
                        maxCameraOrbit: "auto auto 500%", // 最大距離をさらに遠くに
                        cameraOrbit: "45deg 75deg 120%", // 初期カメラ位置を遠くに
                        // 追加のカメラ設定
                        fieldOfView: "45deg", // 視野角を広くしてモデル全体が見えるように
                        // 透明度問題を解決するための設定
                        shadowIntensity: 0.3,
                        shadowSoftness: 0.5,
                        environmentImage: null, // 環境マッピングを無効化
                      ),
                      // 元の写真（右下最前面）
                      if (widget.originalImageUrl != null)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _showFullScreenImage(context),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  widget.originalImageUrl!,
                                  width: 120,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 120,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.moleculeName,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      if (widget.formula != null &&
                          widget.formula!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            widget.formula!,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        '原子の色分け:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _buildElementColorChips(),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '操作方法:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text('• ドラッグ: 回転'),
                      const Text('• ピンチ: 拡大・縮小'),
                      const Text('• 自動回転: ON'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('閉じる'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildElementColorChips() {
    if (widget.formula == null || widget.formula!.isEmpty) {
      return [];
    }

    // 元素記号と色・日本語名のマッピング
    final Map<String, Map<String, dynamic>> elementData = {
      'H': {'color': Colors.white, 'name': '水素'},
      'B': {'color': const Color(0xFFEC7062), 'name': 'ホウ素'},
      'C': {'color': const Color(0xFF444444), 'name': '炭素'},
      'N': {'color': const Color(0xFF3048C9), 'name': '窒素'},
      'O': {'color': const Color(0xFFFF0D0D), 'name': '酸素'},
      'F': {'color': const Color(0xFF90E050), 'name': 'フッ素'},
      'Ne': {'color': const Color(0xFFB3E3F5), 'name': 'ネオン'},
      'Na': {'color': const Color(0xFFAB5CF2), 'name': 'ナトリウム'},
      'Mg': {'color': const Color(0xFF8AFF00), 'name': 'マグネシウム'},
      'Al': {'color': const Color(0xFFBFA6A6), 'name': 'アルミニウム'},
      'Si': {'color': const Color(0xFFF0C8A0), 'name': 'ケイ素'},
      'P': {'color': const Color(0xFFFF8C00), 'name': 'リン'},
      'S': {'color': const Color(0xFFFFFF30), 'name': '硫黄'},
      'Cl': {'color': const Color(0xFF1FF01F), 'name': '塩素'},
      'Ar': {'color': const Color(0xFF80D1E3), 'name': 'アルゴン'},
      'K': {'color': const Color(0xFF8F40D4), 'name': 'カリウム'},
      'Ca': {'color': const Color(0xFF3DFF00), 'name': 'カルシウム'},
      'Ti': {'color': const Color(0xFFBFC2C7), 'name': 'チタン'},
      'Cr': {'color': const Color(0xFF8A99C7), 'name': 'クロム'},
      'Mn': {'color': const Color(0xFF9C7AC7), 'name': 'マンガン'},
      'Fe': {'color': const Color(0xFFE06633), 'name': '鉄'},
      'Co': {'color': const Color(0xFFF090A0), 'name': 'コバルト'},
      'Ni': {'color': const Color(0xFF50D050), 'name': 'ニッケル'},
      'Cu': {'color': const Color(0xFFC88033), 'name': '銅'},
      'Zn': {'color': const Color(0xFF7D80B0), 'name': '亜鉛'},
      'Br': {'color': const Color(0xFFA62929), 'name': '臭素'},
      'Kr': {'color': const Color(0xFF5CB8D1), 'name': 'クリプトン'},
      'Ag': {'color': const Color(0xFFC0C0C0), 'name': '銀'},
      'I': {'color': const Color(0xFF940094), 'name': 'ヨウ素'},
      'Xe': {'color': const Color(0xFF429EB0), 'name': 'キセノン'},
      'Pt': {'color': const Color(0xFFD0D0E0), 'name': '白金'},
      'Au': {'color': const Color(0xFFFFD123), 'name': '金'},
    };

    // 分子式から元素記号を抽出（正規表現）
    final RegExp elementRegex = RegExp(r'([A-Z][a-z]?)');
    final Set<String> elements = elementRegex
        .allMatches(widget.formula!)
        .map((match) => match.group(1)!)
        .toSet();

    // 抽出された元素のみのチップを作成
    return elements
        .where((element) => elementData.containsKey(element))
        .map((element) {
      final data = elementData[element]!;
      return _AtomColorChip(
        element: element,
        color: data['color'],
        name: data['name'],
      );
    }).toList();
  }

  @override
  void dispose() {
    // 一時ファイルをクリーンアップ（Web環境では不要）
    if (_glbUrl != null && !kIsWeb) {
      try {
        File(_glbUrl!).deleteSync();
      } catch (e) {
        // エラーは無視（ファイルが既に削除されている可能性）
      }
    }
    super.dispose();
  }

  /// 元の写真をフルスクリーン表示するダイアログ
  void _showFullScreenImage(BuildContext context) {
    if (widget.originalImageUrl == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.originalImageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '画像を表示できません',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AtomColorChip extends StatelessWidget {
  final String element;
  final Color color;
  final String name;

  const _AtomColorChip({
    required this.element,
    required this.color,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: color == Colors.white ? Colors.grey : Colors.transparent,
                width: color == Colors.white ? 1 : 0,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('$element ($name)', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
