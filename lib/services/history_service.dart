import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:team_25_app/models/compound.dart';
import 'package:team_25_app/models/history_item.dart';
import 'package:team_25_app/services/image_compression_service.dart';

part 'history_service.g.dart';

@riverpod
class HistoryService extends _$HistoryService {
  @override
  Future<List<HistoryItem>> build() async {
    // 初期データを読み込む
    return fetchHistories();
  }

  /// 履歴一覧を取得
  Future<List<HistoryItem>> fetchHistories({String? userId}) async {
    try {
      // 一時的に全ての履歴を取得（後でユーザーフィルタリングを追加予定）

      final querySnapshot = await FirebaseFirestore.instance
          .collection('histories')
          .orderBy('createdAt', descending: true)
          .get();

      final histories = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // DocumentIDをidフィールドに設定
        return HistoryItem.fromJson(data);
      }).toList();

      return histories;
    } catch (e) {
      print('Error fetching histories: $e');
      return [];
    }
  }

  /// 履歴を保存
  Future<void> saveHistory(HistoryItem history) async {
    try {
      await FirebaseFirestore.instance
          .collection('histories')
          .doc(history.id)
          .set(history.toJson());

      // 状態を更新
      state = AsyncData([history, ...state.value ?? []]);
    } catch (e) {
      print('Error saving history: $e');
      rethrow;
    }
  }

  /// 新しい履歴アイテムを作成（画像アップロード含む）
  Future<HistoryItem> createHistory({
    required String objectName,
    required List<Compound> compounds,
    required List<String> cids,
    required Uint8List imageData,
    String? userId,
  }) async {
    try {
      print('createHistory called with objectName: $objectName');
      final uid = userId ?? 'anonymous';
      final historyId = FirebaseFirestore.instance
          .collection('histories')
          .doc()
          .id;
      print('Generated historyId: $historyId');

      // 画像を圧縮してからBase64に変換
      print('Compressing image...');
      final compressedImageData = await ImageCompressionService.compressImage(
        imageData,
      );
      print(
        'Image compressed: ${imageData.length} -> ${compressedImageData.length} bytes',
      );

      final base64Image = base64Encode(compressedImageData);
      final imageUrl = 'data:image/jpeg;base64,$base64Image';
      print('Image converted to Base64 (${base64Image.length} chars)');

      // HistoryItemを作成
      final historyItem = HistoryItem(
        id: historyId,
        userId: uid,
        imageUrl: imageUrl,
        objectName: objectName,
        compounds: compounds,
        cids: cids,
        isFavorite: false,
        createdAt: DateTime.now(),
      );

      // Firestoreに保存（toJson()でシリアライズ）
      await FirebaseFirestore.instance
          .collection('histories')
          .doc(historyId)
          .set({
            ...historyItem.toJson(),
            'compounds': compounds.map((c) => c.toJson()).toList(),
          });

      print('History saved to Firestore successfully');

      // 状態を更新
      state = AsyncData([historyItem, ...state.value ?? []]);

      return historyItem;
    } catch (e) {
      print('Error creating history: $e');
      rethrow;
    }
  }

  /// お気に入り状態を切り替え
  Future<void> toggleFavorite(String historyId) async {
    try {
      final currentHistories = state.value ?? [];
      final historyIndex = currentHistories.indexWhere(
        (h) => h.id == historyId,
      );

      if (historyIndex == -1) return;

      final history = currentHistories[historyIndex];
      final updatedHistory = history.copyWith(isFavorite: !history.isFavorite);

      // Firestoreを更新
      await FirebaseFirestore.instance
          .collection('histories')
          .doc(historyId)
          .update({'isFavorite': updatedHistory.isFavorite});

      // ローカル状態を更新
      final updatedHistories = [...currentHistories];
      updatedHistories[historyIndex] = updatedHistory;
      state = AsyncData(updatedHistories);
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }

  /// 履歴を削除（将来的に実装する場合）
  Future<void> deleteHistory(String historyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('histories')
          .doc(historyId)
          .delete();

      // ローカル状態からも削除
      final currentHistories = state.value ?? [];
      final updatedHistories = currentHistories
          .where((h) => h.id != historyId)
          .toList();
      state = AsyncData(updatedHistories);
    } catch (e) {
      print('Error deleting history: $e');
      rethrow;
    }
  }

  /// 履歴を再読み込み
  Future<void> refresh() async {
    state = const AsyncLoading();
    final histories = await fetchHistories();
    state = AsyncData(histories);
  }
}
