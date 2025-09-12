import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/detection_result.dart';
import '../../services/api_service.dart';

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


    if (_isLoading) return;

    final picker = ImagePicker();
    XFile? picked;

    try {
      picked = await picker.pickImage(

        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
    } catch (e) {
      if (!mounted) return;

      return;
    }

    if (picked == null) {

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final file = File(picked.path);
      final Uint8List imageBytes = await picked.readAsBytes();

      final DetectionResult result = await ApiService.analyzeImage(
        imageBytes,
        picked.mimeType,
      );


      HistoryStore.add(
        HistoryItem(
          objectName: result.objectName,
          viewedAt: DateTime.now(),
          molecules: result.molecules,
          imageFile: file,

        ),
      );

      if (!mounted) return;

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

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
