import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:team_25_app/data/element_data.dart';
import 'package:team_25_app/models/element.dart';

part 'encyclopedia_service.g.dart';

@Riverpod(keepAlive: true)
class EncyclopediaService extends _$EncyclopediaService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Future<List<Element>> build() async {
    // 初期データを読み込む
    return fetchUserProgress();
  }

  /// 現在のユーザーIDを取得
  String get _currentUserId {
    return _auth.currentUser?.uid ?? 'anonymous';
  }

  /// ユーザーの図鑑進捗を取得
  Future<List<Element>> fetchUserProgress() async {
    try {
      final userId = _currentUserId;
      
      // Firestoreからユーザーの進捗を取得
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data()!.containsKey('encyclopedia_progress')) {
        final progressData = userDoc.data()!['encyclopedia_progress'] as Map<String, dynamic>;
        final discoveredSymbols = Set<String>.from(progressData['discovered'] ?? []);
        
        // ElementDataのデータに進捗を反映
        return ElementData.allElements.map((element) {
          return element.copyWith(
            discovered: discoveredSymbols.contains(element.symbol),
          );
        }).toList();
      } else {
        // ユーザーの進捗がない場合、またはanonymousユーザーの場合はElementDataのデフォルト状態を返す
        return List.from(ElementData.allElements);
      }
    } catch (e) {
      print('Error fetching encyclopedia progress: $e');
      // エラーの場合はデフォルト状態を返す
      return List.from(ElementData.allElements);
    }
  }

  /// 元素の発見状態を切り替え
  Future<void> toggleElementDiscovered(String elementSymbol) async {
    try {
      final currentElements = state.value ?? [];
      final elementIndex = currentElements.indexWhere(
        (e) => e.symbol == elementSymbol,
      );

      if (elementIndex == -1) return;

      final element = currentElements[elementIndex];
      final updatedElement = element.copyWith(discovered: !element.discovered);

      // ローカル状態を更新
      final updatedElements = [...currentElements];
      updatedElements[elementIndex] = updatedElement;
      state = AsyncData(updatedElements);

      // Firestoreに保存
      await _saveProgressToFirestore(updatedElements);
    } catch (e) {
      print('Error toggling element discovery: $e');
      rethrow;
    }
  }

  /// 複数の元素を一度に発見済みに設定
  Future<void> discoverElements(List<String> elementSymbols) async {
    try {
      // Ensure the initial state is loaded by awaiting the future.
      final currentElements = await future;
      var updatedElements = [...currentElements];
      bool hasChanges = false;

      for (final symbol in elementSymbols) {
        final elementIndex = updatedElements.indexWhere(
          (e) => e.symbol == symbol,
        );

        if (elementIndex != -1) {
          final element = updatedElements[elementIndex];
          if (!element.discovered) {
            updatedElements[elementIndex] = element.copyWith(discovered: true);
            hasChanges = true;
          }
        }
      }

if (hasChanges) {
  // Firestore 書き込み
  await _saveProgressToFirestore(updatedElements);

  // Provider がまだ生きていれば state 更新
  if (ref.mounted) {
    state = AsyncData(updatedElements);
  }
}
    } catch (e) {
      print('Error discovering elements: $e');
      rethrow;
    } 
  }

  /// 進捗をFirestoreに保存
  Future<void> _saveProgressToFirestore(List<Element> elements) async {
    try {
      final userId = _currentUserId;
      final discoveredSymbols = elements
          .where((e) => e.discovered)
          .map((e) => e.symbol)
          .toList();

      final progressData = {
        'encyclopedia_progress': {
          'discovered': discoveredSymbols,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      };

      await _firestore.collection('users').doc(userId).set(
            progressData,
            SetOptions(merge: true),
          );
    } catch (e) {
      print('Error saving progress to Firestore: $e');
      rethrow;
    }
  }

  /// 進捗を再読み込み
  Future<void> refresh() async {
    state = const AsyncLoading();
    final elements = await fetchUserProgress();
    state = AsyncData(elements);
  }
  
  // ... (他のメソッドは変更なし)
  /// 完了率を取得
  double getCompletionRate() {
    final elements = state.value ?? [];
    if (elements.isEmpty) return 0.0;
    
    final discoveredCount = elements.where((e) => e.discovered).length;
    return discoveredCount / elements.length;
  }

  /// 発見済み元素数を取得
  int getDiscoveredCount() {
    final elements = state.value ?? [];
    return elements.where((e) => e.discovered).length;
  }

  /// 全元素数を取得
  int getTotalCount() {
    final elements = state.value ?? [];
    return elements.length;
  }

  /// 全て発見済みかどうか
  bool isCompleted() {
    final elements = state.value ?? [];
    return elements.isNotEmpty && elements.every((e) => e.discovered);
  }
}
