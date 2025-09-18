import 'package:freezed_annotation/freezed_annotation.dart';

part 'element.freezed.dart';
part 'element.g.dart';

@freezed
abstract class Element with _$Element {
  const factory Element({
    required String symbol, // 元素記号（H, C, O等）
    required String name, // 元素名（水素、炭素、酸素等）
    required int atomicNumber, // 原子番号
    String? iconUrl, // アイコン画像URL
  }) = _Element;

  factory Element.fromJson(Map<String, dynamic> json) =>
      _$ElementFromJson(json);
}

@freezed
abstract class UserElementProgress with _$UserElementProgress {
  const factory UserElementProgress({
    required String userId, // ユーザーID（Firebase Auth UID）
    required String elementSymbol, // 元素記号
    required bool isDiscovered, // 発見済みフラグ
    DateTime? discoveredAt, // 発見日時
    @Default(0) int viewCount, // 閲覧回数（将来の拡張用）
  }) = _UserElementProgress;

  factory UserElementProgress.fromJson(Map<String, dynamic> json) =>
      _$UserElementProgressFromJson(json);
}
