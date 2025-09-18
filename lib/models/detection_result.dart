import 'package:freezed_annotation/freezed_annotation.dart';

import 'compound.dart';

part 'detection_result.freezed.dart';
part 'detection_result.g.dart';

@freezed
abstract class DetectionResult with _$DetectionResult {
  const factory DetectionResult({
    required String objectName,
    required List<Compound> molecules,
  }) = _DetectionResult;

  factory DetectionResult.fromJson(Map<String, dynamic> json) =>
      _$DetectionResultFromJson(json);

  // APIレスポンス用
  factory DetectionResult.fromApiResponse(Map<String, dynamic> json) {
    try {
      var moleculeList = <Compound>[];
      if (json['molecules'] != null) {
        json['molecules'].forEach((v) {
          try {
            // APIレスポンスからCompoundを作成
            final formula = v['formula'] ?? '';
            print('Processing molecule: ${v['name']} with formula: $formula');
            
            moleculeList.add(
              Compound(
                cid: v['cid']?.toString() ?? '',
                name: v['name'] ?? '',
                formula: formula,
                elements: Compound.extractElementsFromFormula(formula),
                description: v['description'] ?? '',
              ),
            );
            print('Successfully added molecule: ${v['name']}');
          } catch (e) {
            print('Error processing molecule ${v['name']}: $e');
            print('Stack trace: ${StackTrace.current}');
          }
        });
      }

      final result = DetectionResult(
        // 'object' キーを 'objectName' にマッピング
        objectName: json['object'] ?? '',
        molecules: moleculeList,
      );
      
      print('Successfully created DetectionResult: ${result.objectName} with ${result.molecules.length} molecules');
      return result;
    } catch (e) {
      print('Error in fromApiResponse: $e');
      rethrow;
    }
  }
}
