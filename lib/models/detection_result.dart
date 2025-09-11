import 'molecule.dart';

class DetectionResult {
  final String objectName;
  final String objectCategory;
  final List<Molecule> molecules;

  DetectionResult({
    required this.objectName,
    required this.objectCategory,
    required this.molecules,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) => DetectionResult(
        objectName: json['object_name'] ?? '',
        objectCategory: json['object_category'] ?? '',
        molecules: (json['molecules'] as List<dynamic>? ?? [])
            .map((e) => Molecule.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'object_name': objectName,
        'object_category': objectCategory,
        'molecules': molecules.map((e) => e.toJson()).toList(),
      };
}