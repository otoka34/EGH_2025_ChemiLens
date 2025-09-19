import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:team_25_app/screens/result/result_screen.dart';
import 'package:team_25_app/screens/collection/history_screen.dart';
import 'package:team_25_app/services/api_service.dart';
import 'package:team_25_app/services/history_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/theme/app_colors.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isTakingPicture = false;
  bool _permissionDenied = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      // Web用の権限チェック
      if (kIsWeb) {
        // Webではpermission_handlerは使えないので、直接カメラを初期化
        await _setupCamera();
      } else {
        // モバイル用の権限チェック
        final status = await Permission.camera.status;

        if (status.isDenied) {
          final result = await Permission.camera.request();
          if (result.isGranted) {
            await _setupCamera();
          } else {
            setState(() {
              _permissionDenied = true;
              _errorMessage = 'カメラの使用許可が必要です';
            });
          }
        } else if (status.isPermanentlyDenied) {
          setState(() {
            _permissionDenied = true;
            _errorMessage = 'カメラの使用許可が必要です。設定アプリから権限を付与してください。';
          });
        } else if (status.isGranted) {
          await _setupCamera();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'カメラの初期化に失敗しました: $e';
      });
    }
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = '利用可能なカメラが見つかりません';
        });
        return;
      }

      // 背面カメラを優先、なければ最初のカメラを使用
      final camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'カメラの起動に失敗しました: $e';
      });
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_isTakingPicture) return;

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final XFile photo = await _controller!.takePicture();

      // MIMEタイプを明示的に設定
      final imageBytes = await photo.readAsBytes();
      final XFile processedImage = XFile.fromData(
        imageBytes,
        mimeType: 'image/jpeg',
        name: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await _processImage(processedImage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('写真の撮影に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isLoading) return;

    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        // MIMEタイプを明示的に設定し直す
        final imageBytes = await picked.readAsBytes();
        final XFile processedImage = XFile.fromData(
          imageBytes,
          mimeType: picked.mimeType,
          name: picked.name,
        );
        await _processImage(processedImage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像選択エラー: $e')),
        );
      }
    }
  }

  Future<void> _processImage(XFile image) async {
    setState(() {
      _isLoading = true;
    });

    try {

      final imageBytes = await image.readAsBytes();

      // APIで画像を解析
      // image.mimeTypeがnullの場合のみデフォルト値を使用（カメラ撮影時など）
      final mimeType = image.mimeType;

      final result = await ApiService.analyzeImage(
        imageBytes,
        mimeType ?? 'image/jpeg',
      );


      // 履歴を保存
      final compounds = result.molecules;
      final cids = compounds.map((c) => c.cid).toList();

      // mountedチェックを追加してprovider破棄後の使用を防ぐ
      if (mounted) {
        try {
          await ref.read(historyServiceProvider.notifier).createHistory(
            objectName: result.objectName,
            compounds: compounds,
            cids: cids,
            imageData: imageBytes,
          );
        } catch (e) {
          // 履歴保存の失敗は結果画面への遷移を妨げない
          debugPrint('History save failed: $e');
        }
      }

      if (!mounted) return;

      // 結果画面へ（Webでは画像のバイトデータを渡す）
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              ResultScreen(imageFile: image, detection: result),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像の解析に失敗しました: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentDirection = _controller!.description.lensDirection;
    final newCamera = _cameras!.firstWhere(
      (camera) => camera.lensDirection != currentDirection,
      orElse: () => _cameras!.first,
    );

    await _controller?.dispose();

    _controller = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('カメラの切り替えに失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // 戻るボタンが押された時の処理
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HistoryScreen(),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('画像を解析中...'),
          ],
        ),
      );
    }

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'カメラの使用許可が必要です',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (!kIsWeb)
                ElevatedButton.icon(
                  onPressed: () async {
                    if (await Permission.camera.isPermanentlyDenied) {
                      await openAppSettings();
                    } else {
                      await _initializeCamera();
                    }
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('設定を開く'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null && !_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeCamera,
                child: const Text('再試行'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('カメラを起動中...'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // カメラプレビュー
        Positioned.fill(
          child: CameraPreview(_controller!),
        ),

        // 上部のコントロール（カメラ切り替え）
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // カメラ切り替えボタン
                if ((_cameras?.length ?? 0) > 1)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 下部の撮影ボタンとコントロール
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 戻るボタン
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                // 撮影ボタン
                GestureDetector(
                  onTap: _isTakingPicture ? null : _takePicture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: _isTakingPicture ? Colors.grey : Colors.white,
                        width: 4,
                      ),
                    ),
                    child: _isTakingPicture
                        ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isTakingPicture
                                  ? Colors.grey
                                  : AppColors.primary,
                            ),
                          ),
                  ),
                ),

                // ギャラリーボタン
                IconButton(
                  onPressed: _isLoading ? null : _pickFromGallery,
                  icon: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}