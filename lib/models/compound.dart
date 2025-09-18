import 'package:freezed_annotation/freezed_annotation.dart';

part 'compound.freezed.dart';
part 'compound.g.dart';

@freezed
abstract class Compound with _$Compound {
  const factory Compound({
    required String cid, // PubChem CID
    required String name, // 化合物名
    required String formula, // 分子式
    required List<String> elements, // 含まれる元素記号
    required String description, // 説明文
  }) = _Compound;

  factory Compound.fromJson(Map<String, dynamic> json) =>
      _$CompoundFromJson(json);

  // 分子式から元素記号を抽出
  static List<String> extractElementsFromFormula(String formula) {
    if (formula.isEmpty) return [];
    final elements = <String>{};

    // カンマ区切りの場合を処理（例: "C, H, O, N, S"）
    if (formula.contains(',')) {
      final parts = formula.split(',');
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty && RegExp(r'^[A-Z][a-z]?$').hasMatch(trimmed)) {
          elements.add(trimmed);
        }
      }
    } else {
      // 通常の分子式形式を処理（例: "H2O", "C6H12O6"）
      final regex = RegExp(r'([A-Z][a-z]?)');
      final matches = regex.allMatches(formula);

      for (final match in matches) {
        final element = match.group(1);
        if (element != null) {
          elements.add(element);
        }
      }
    }

    return elements.toList();
  }
}
