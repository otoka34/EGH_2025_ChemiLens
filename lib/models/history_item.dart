import 'package:freezed_annotation/freezed_annotation.dart';

import 'compound.dart';

part 'history_item.freezed.dart';
part 'history_item.g.dart';

@freezed
abstract class HistoryItem with _$HistoryItem {
  const factory HistoryItem({
    required String id, // 履歴ID（Firestore document ID）
    required String userId, // ユーザーID（Firebase Auth UID）
    required String imageUrl, // Firebase Storageの画像URL
    required String objectName, // 推測された物体名称
    required List<Compound> compounds, // 検出された化合物（3-5個）
    required List<String> cids, // APIから返された全化合物のCID
    @Default(false) bool isFavorite, // お気に入りフラグ
    required DateTime createdAt, // 撮影日時
  }) = _HistoryItem;

  factory HistoryItem.fromJson(Map<String, dynamic> json) =>
      _$HistoryItemFromJson(json);
}
