import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:team_25_app/models/compound.dart';
import 'package:team_25_app/models/history_item.dart';
import 'package:team_25_app/services/encyclopedia_service.dart';
import 'package:team_25_app/services/image_compression_service.dart';

part 'history_service.g.dart';

@Riverpod(keepAlive: true)
class HistoryService extends _$HistoryService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _historiesCollection(String? userId) {
    final uid = userId ?? _auth.currentUser?.uid ?? 'anonymous';
    return _firestore.collection('users').doc(uid).collection('histories');
  }

  @override
  Future<List<HistoryItem>> build() async {
    // 初期データを読み込む
    return fetchHistories();
  }

  /// 履歴一覧を取得
  Future<List<HistoryItem>> fetchHistories({String? userId}) async {
    try {
      final targetUserId = userId ?? _auth.currentUser?.uid ?? 'anonymous';
      print('🔍 [DEBUG] fetchHistories called for userId: $targetUserId');

      final querySnapshot = await _historiesCollection(targetUserId)
          .orderBy('createdAt', descending: true)
          .get();

      final histories = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return HistoryItem.fromJson(data);
      }).toList();

      // If a logged-in user has no histories, check for anonymous histories to migrate
      if (targetUserId != 'anonymous' && histories.isEmpty) {
        print('🔍 [DEBUG] No histories for logged-in user, checking anonymous data...');
        final anonymousHistories = await fetchHistories(userId: 'anonymous');
        if (anonymousHistories.isNotEmpty) {
          print('🔍 [DEBUG] Found ${anonymousHistories.length} anonymous histories to migrate.');
          for (final history in anonymousHistories) {
            // Re-create history for the logged-in user
            await createHistory(
              objectName: history.objectName,
              compounds: history.compounds,
              cids: history.cids,
              imageData: base64Decode(history.imageUrl.split(',').last), // This is a bit of a hack
              userId: targetUserId,
            );
            // Delete the old anonymous history
            await _historiesCollection('anonymous').doc(history.id).delete();
          }
          // Re-fetch histories for the current user
          return await fetchHistories(userId: targetUserId);
        }
      }

      print('🔍 [DEBUG] Returning ${histories.length} histories for $targetUserId');
      return histories;
    } catch (e) {
      print('❌ Error fetching histories: $e');
      return [];
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
      final uid = userId ?? _auth.currentUser?.uid ?? 'anonymous';
      final historyId = _historiesCollection(uid).doc().id;
      print('Generated historyId: $historyId for user: $uid');

      // 画像を圧縮してからBase64に変換
      final compressedImageData = await ImageCompressionService.compressImage(imageData);
      final base64Image = base64Encode(compressedImageData);
      final imageUrl = 'data:image/jpeg;base64,$base64Image';

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

      // Firestoreに保存
      final saveData = {
        ...historyItem.toJson(),
        'compounds': historyItem.compounds.map((c) => c.toJson()).toList(),
      };
      await _historiesCollection(uid).doc(historyId).set(saveData);

      // 化合物から元素を抽出して図鑑に反映
      final elementSymbols = <String>{};
      for (final compound in compounds) {
        elementSymbols.addAll(compound.elements);
      }
      
      if (elementSymbols.isNotEmpty) {
        try {
          print('Calling discoverElements from createHistory with: ${elementSymbols.toList()}');
          // Wait for the encyclopedia provider to be ready before trying to update it.
          await ref.read(encyclopediaServiceProvider.future);
          // Now call the update method.
          await ref.read(encyclopediaServiceProvider.notifier).discoverElements(elementSymbols.toList());
          print('Finished calling discoverElements from createHistory.');
        } catch (e) {
          print('Error updating encyclopedia progress from createHistory: $e');
        }
      }
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
  Future<void> toggleFavorite(String historyId, String userId) async {
    try {
      final currentHistories = state.value ?? [];
      final historyIndex = currentHistories.indexWhere((h) => h.id == historyId);

      if (historyIndex == -1) return;

      final history = currentHistories[historyIndex];
      final updatedHistory = history.copyWith(isFavorite: !history.isFavorite);

      // Firestoreを更新
      await _historiesCollection(userId).doc(historyId).update({'isFavorite': updatedHistory.isFavorite});

      // ローカル状態を更新
      final updatedHistories = [...currentHistories];
      updatedHistories[historyIndex] = updatedHistory;
      state = AsyncData(updatedHistories);
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }

  /// 履歴を削除
  Future<void> deleteHistory(String historyId, String userId) async {
    try {
      await _historiesCollection(userId).doc(historyId).delete();

      // ローカル状態からも削除
      final currentHistories = state.value ?? [];
      final updatedHistories = currentHistories.where((h) => h.id != historyId).toList();
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
  
  // fetchHistoriesByEmail is deprecated due to new data structure
  Future<List<HistoryItem>> fetchHistoriesByEmail(String email) async {
    print('⚠️ fetchHistoriesByEmail is deprecated and will not return results with the new data structure.');
    return [];
  }
}
