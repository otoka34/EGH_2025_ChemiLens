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

@riverpod
class HistoryService extends _$HistoryService {
  @override
  Future<List<HistoryItem>> build() async {
    // 初期データを読み込む
    return fetchHistories();
  }

  /// メールアドレスで履歴を検索
  Future<List<HistoryItem>> fetchHistoriesByEmail(String email) async {
    try {
      print('🔍 [DEBUG] fetchHistoriesByEmail called with email: $email');
      
      // まず、userEmailフィールドがある場合を検索 (インデックス待ちのため一時的にorderBy削除)
      final emailQuery = await FirebaseFirestore.instance
          .collection('histories')
          .where('userEmail', isEqualTo: email)
          .get();
      
      print('🔍 [DEBUG] Found ${emailQuery.docs.length} documents with userEmail: $email');
      
      final histories = emailQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return HistoryItem.fromJson(data);
      }).toList();
      
      return histories;
    } catch (e) {
      print('❌ Error fetching histories by email: $e');
      return [];
    }
  }

  /// 履歴一覧を取得
  Future<List<HistoryItem>> fetchHistories({String? userId}) async {
    try {
      // 現在ログイン中のユーザーIDを取得
      final currentUser = FirebaseAuth.instance.currentUser;
      final targetUserId = userId ?? currentUser?.uid ?? 'anonymous';

      print('🔍 [DEBUG] fetchHistories called');
      print('🔍 [DEBUG] currentUser: ${currentUser?.uid}');
      print('🔍 [DEBUG] currentUser email: ${currentUser?.email}');
      print('🔍 [DEBUG] targetUserId: $targetUserId');

      // まず全ての履歴ドキュメントを確認
      final allDocsSnapshot = await FirebaseFirestore.instance
          .collection('histories')
          .get();
      print('🔍 [DEBUG] Total documents in histories collection: ${allDocsSnapshot.docs.length}');
      
      for (var doc in allDocsSnapshot.docs) {
        final data = doc.data();
        print('🔍 [DEBUG] All docs - ${doc.id}: userId=${data['userId']}, userEmail=${data['userEmail'] ?? 'N/A'}, objectName=${data['objectName'] ?? 'N/A'}');
      }

      Set<HistoryItem> allHistories = {};

      // 1. userIdで検索 (インデックス待ちのため一時的にorderBy削除)
      Query userIdQuery = FirebaseFirestore.instance
          .collection('histories')
          .where('userId', isEqualTo: targetUserId);

      final userIdQuerySnapshot = await userIdQuery.get();
      print('🔍 [DEBUG] Found ${userIdQuerySnapshot.docs.length} documents for userId: $targetUserId');

      for (var doc in userIdQuerySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        allHistories.add(HistoryItem.fromJson(data));
      }

      // 2. ログインユーザーの場合はメールアドレスでも検索
      if (currentUser != null && currentUser.email != null && targetUserId != 'anonymous') {
        print('🔍 [DEBUG] Also searching by email: ${currentUser.email}');
        final emailHistories = await fetchHistoriesByEmail(currentUser.email!);
        allHistories.addAll(emailHistories);
      }

      // 3. anonymousデータも含める場合（未ログインユーザー、または追加データとして）
      if (targetUserId == 'anonymous') {
        print('🔍 [DEBUG] Searching for anonymous data');
        Query anonymousQuery = FirebaseFirestore.instance
            .collection('histories')
            .where('userId', isEqualTo: 'anonymous');

        final anonymousSnapshot = await anonymousQuery.get();
        print('🔍 [DEBUG] Found ${anonymousSnapshot.docs.length} anonymous documents');
        
        for (var doc in anonymousSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          allHistories.add(HistoryItem.fromJson(data));
        }
      }

      // 4. 結果をリストに変換してソート
      final resultList = allHistories.toList();
      resultList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('🔍 [DEBUG] Returning ${resultList.length} histories total');
      return resultList;
    } catch (e) {
      print('❌ Error fetching histories: $e');
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
      // 現在ログイン中のユーザーIDを取得、未ログインの場合は'anonymous'
      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = userId ?? currentUser?.uid ?? 'anonymous';
      final userEmail = currentUser?.email;
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
      final saveData = {
        ...historyItem.toJson(),
        'compounds': compounds.map((c) => c.toJson()).toList(),
      };
      
      // メールアドレスも保存（検索用）
      if (userEmail != null) {
        saveData['userEmail'] = userEmail;
      }
      
      await FirebaseFirestore.instance
          .collection('histories')
          .doc(historyId)
          .set(saveData);

      print('History saved to Firestore successfully');

      // 化合物から元素を抽出して図鑑に反映
      final elementSymbols = <String>{};
      for (final compound in compounds) {
        elementSymbols.addAll(compound.elements);
      }
      
      if (elementSymbols.isNotEmpty) {
        try {
          final encyclopediaService = ref.read(encyclopediaServiceProvider.notifier);
          await encyclopediaService.discoverElements(elementSymbols.toList());
        } catch (e) {
          print('Error updating encyclopedia progress: $e');
          // 図鑑の更新に失敗しても履歴保存は成功として扱う
        }
      }

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
