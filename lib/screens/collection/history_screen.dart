import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:team_25_app/screens/collection/widgets/app_bar_with_icon.dart';
import 'package:team_25_app/screens/collection/widgets/camera_floating_action_buttons.dart';
import 'package:team_25_app/screens/collection/widgets/history_list.dart';
import 'package:team_25_app/screens/collection/widgets/history_tab_bar.dart';
import 'package:team_25_app/screens/result/result_screen.dart';
import 'package:team_25_app/services/api_service.dart';
import 'package:team_25_app/services/history_filter_providers.dart';
import 'package:team_25_app/services/history_service.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
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
        ? HistoryFilterType.favorites
        : HistoryFilterType.all;
    ref.read(historyFilterProvider.notifier).setFilter(filter);
  }

  Future<void> _pickFrom(ImageSource source) async {
    if (_isLoading) return;

    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        await _processPickedImage(picked);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('画像選択エラー: $e')));
    }
  }

  Future<void> _processPickedImage(XFile pickedFile) async {
    setState(() => _isLoading = true);

    try {
      final imageBytes = await pickedFile.readAsBytes();

      final result = await ApiService.analyzeImage(
        imageBytes,
        pickedFile.mimeType ?? 'image/jpeg',
      );

      print('Analysis complete: ${result.objectName}');
      print('Molecules count: ${result.molecules.length}');

      final compounds = result.molecules;
      final cids = compounds.map((c) => c.cid).toList();

      // 履歴を保存
      print('Saving history...');
      await ref
          .read(historyServiceProvider.notifier)
          .createHistory(
            objectName: result.objectName,
            compounds: compounds,
            cids: cids,
            imageData: imageBytes,
          );

      print('History saved, navigating to result screen...');

      if (!mounted) return;

      // 結果画面へ（Webでは画像のバイトデータを渡す）
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              ResultScreen(imageFile: pickedFile, detection: result),
        ),
      );

      print('Navigation completed');
    } catch (e, stackTrace) {
      print('Error in _processPickedImage: $e');
      print('Stack trace: $stackTrace');
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
      appBar: const AppBarWithIcon(),
      floatingActionButton: CameraFloatingActionButtons(
        isLoading: _isLoading,
        onPickImage: _pickFrom,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HistoryTabBar(tabController: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  HistoryList(targetFilter: HistoryFilterType.favorites),
                  HistoryList(targetFilter: HistoryFilterType.all),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
