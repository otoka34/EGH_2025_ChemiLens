import 'molecule.dart';

class DetectionResult {
  final String objectName;
  final List<Molecule> molecules;

  DetectionResult({
    required this.objectName,
    required this.molecules,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    var moleculeList = <Molecule>[];
    if (json['molecules'] != null) {
      json['molecules'].forEach((v) {
        moleculeList.add(Molecule.fromJson(v));
      });
    }

    return DetectionResult(
      // 'object' キーを 'objectName' にマッピング
      objectName: json['object'] ?? '',
      molecules: moleculeList,
    );
  }

  // toJsonは履歴保存などで使う可能性があるので残しておく
  Map<String, dynamic> toJson() => {
        'object': objectName,
        'molecules': molecules.map((e) => e.toJson()).toList(),
      };
}
