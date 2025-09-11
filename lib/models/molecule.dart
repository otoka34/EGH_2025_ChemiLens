class Molecule {
  final String nameJp;
  final String nameEn;
  final String formula;
  final String description;
  final double confidence; // 0.0 ~ 1.0

  Molecule({
    required this.nameJp,
    required this.nameEn,
    required this.formula,
    required this.description,
    required this.confidence,
  });

  factory Molecule.fromJson(Map<String, dynamic> json) => Molecule(
        nameJp: json['name_jp'] ?? '',
        nameEn: json['name_en'] ?? '',
        formula: json['formula'] ?? '',
        description: json['description'] ?? '',
        confidence: (json['confidence'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name_jp': nameJp,
        'name_en': nameEn,
        'formula': formula,
        'description': description,
        'confidence': confidence,
      };
}