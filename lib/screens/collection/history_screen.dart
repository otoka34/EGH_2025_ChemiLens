import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:team_25_app/screens/collection/widgets/history_list.dart';
import 'package:team_25_app/screens/collection/widgets/history_tab_bar.dart';
import 'package:team_25_app/screens/services/history_store.dart';

import '../../models/detection_result.dart';
import '../../services/api_service.dart';
import '../result/result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // モックデータを初期化（デバッグ用）
    HistoryStore.initMockData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    final filter = _tabController.index == 0
        ? HistoryFilter.favorites
        : HistoryFilter.all;
    HistoryStore.setFilter(filter);
  }

  Future<void> _pickFrom(ImageSource source) async {
    if (_isLoading) return;

    debugPrint('Starting image picker with source: $source');

    // シミュレーター環境での対応
    if (kDebugMode && Platform.isIOS) {
      // 利用可能なテスト画像を探す（有機化合物系を優先）
      final List<String> testImagePaths = [
        '/Users/ryousei/programing/hackathon/team-25-app/test_images/coffee_beans.jpg',  // 実際のコーヒー画像（カフェイン）
      ];

      final List<File> availableImages = [];
      for (final path in testImagePaths) {
        final file = File(path);
        if (await file.exists()) {
          availableImages.add(file);
        }
      }

      if (availableImages.isNotEmpty) {
        if (!mounted) return;
        final selectedFile = await showDialog<File>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🔧 開発用画像選択'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'iOSシミュレーターではImagePickerが不安定です。\n開発用テスト画像を選択してください：',
                ),
                const SizedBox(height: 16),
                ...availableImages.map(
                  (file) => ListTile(
                    title: Text(file.path.split('/').last),
                    subtitle: Text(
                      file.path.split('/').length > 1 
                        ? file.path.split('/').skip(file.path.split('/').length - 2).join('/')
                        : file.path,
                    ),
                    onTap: () => Navigator.of(context).pop(file),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: const Text('ImagePickerを試行'),
                  subtitle: const Text('フリーズするかもしれません'),
                  onTap: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
          ),
        );

        if (selectedFile != null) {
          debugPrint('Using selected test image: ${selectedFile.path}');
          await _processTestImage(selectedFile);
          return;
        }
        // selectedFile が null の場合は ImagePicker を試行
      } else {
        // テスト画像が見つからない場合
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ シミュレーター制限'),
            content: const Text(
              'iOSシミュレーターでImagePickerは不安定です。\n'
              '実機でのテストを推奨しますが、試行しますか？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('試行する'),
              ),
            ],
          ),
        );

        if (proceed != true) return;
      }
    }

    // ImagePickerを詳細設定で使用
    final picker = ImagePicker();
    XFile? picked;

    try {
      debugPrint('Opening image picker...');
      
      // シンプルな設定でImagePickerを呼び出し（記事の推奨通り）
      picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      
      debugPrint('Image picker returned: ${picked?.path}');
    } catch (e) {
      debugPrint('Image picker error: $e');
      
      // 権限エラーの場合の詳細情報を表示
      String errorMessage = 'エラー: $e';
      if (e.toString().contains('permission') || e.toString().contains('denied')) {
        errorMessage = '写真ライブラリへのアクセス権限が必要です。設定から権限を許可してください。';
      } else if (e.toString().contains('camera')) {
        errorMessage = 'カメラへのアクセス権限が必要です。設定から権限を許可してください。';
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '再試行',
            onPressed: () => _pickFrom(source),
          ),
        ),
      );
      return;
    }

    if (picked == null) {
      debugPrint('No image selected');
      return;
    }

    // 実際の画像処理を行う
    await _processPickedImage(picked);
  }

  Future<void> _processTestImage(File testFile) async {
    setState(() => _isLoading = true);

    try {
      final Uint8List imageBytes = await testFile.readAsBytes();

      debugPrint('Calling API with test image...');
      final DetectionResult result = await ApiService.analyzeImage(
        imageBytes,
        'image/jpeg',
      );
      debugPrint('API response received: ${result.objectName}');

      HistoryStore.add(
        HistoryItem(
          objectName: result.objectName,
          viewedAt: DateTime.now(),
          molecules: result.molecules,
          imageFile: testFile,
          topMolecule: result.molecules.isNotEmpty
              ? result.molecules.first
              : null,
        ),
      );

      if (!mounted) return;

      // 結果画面へ
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              ResultScreen(imageFile: testFile, detection: result),
        ),
      );
    } catch (e) {
      debugPrint('API error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('解析に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processPickedImage(XFile pickedFile) async {
    setState(() => _isLoading = true);

    try {
      final Uint8List imageBytes = await pickedFile.readAsBytes();
      final File imageFile = File(pickedFile.path);

      debugPrint('Calling API with picked image...');
      final DetectionResult result = await ApiService.analyzeImage(
        imageBytes,
        pickedFile.mimeType ?? 'image/jpeg',
      );
      debugPrint('API response received: ${result.objectName}');

      HistoryStore.add(
        HistoryItem(
          objectName: result.objectName,
          viewedAt: DateTime.now(),
          molecules: result.molecules,
          imageFile: imageFile,
          topMolecule: result.molecules.isNotEmpty
              ? result.molecules.first
              : null,
        ),
      );

      if (!mounted) return;

      // 結果画面へ
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              ResultScreen(imageFile: imageFile, detection: result),
        ),
      );
    } catch (e) {
      debugPrint('API error: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/images/app_bar_icon.svg',
              height: 32,
              width: 32,
            ),
          ],
        ),
        elevation: 0,
      ),
      floatingActionButton: _isLoading
          ? const CircularProgressIndicator()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // アルバム選択用FAB
                FloatingActionButton(
                  heroTag: "album",
                  onPressed: () => _pickFrom(ImageSource.gallery),
                  child: const Icon(Icons.photo_library),
                ),
                const SizedBox(height: 12),
                // カメラ撮影用FAB
                FloatingActionButton(
                  heroTag: "camera",
                  onPressed: () => _pickFrom(ImageSource.camera),
                  child: const Icon(Icons.camera_alt),
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // タブバー
            HistoryTabBar(tabController: _tabController),

            // 履歴リスト本体
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  // お気に入りタブ
                  HistoryList(targetFilter: HistoryFilter.favorites),
                  // すべてタブ
                  HistoryList(targetFilter: HistoryFilter.all),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
