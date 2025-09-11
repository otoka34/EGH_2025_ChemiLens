class Molecule {
  final String name;
  final String description;
  final double confidence;
  final int? cid;
  final String? sdf;

  Molecule({
    required this.name,
    required this.description,
    required this.confidence,
    this.cid,
    this.sdf,
  });

  factory Molecule.fromJson(Map<String, dynamic> json) {
    // confidenceが int の場合も double の場合も対応
    final confidenceValue = json['confidence'];
    final confidence = confidenceValue is int ? confidenceValue.toDouble() / 100.0 : (confidenceValue ?? 0.0) as double;

    return Molecule(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      confidence: confidence,
      cid: json['cid'] as int?,
      sdf: json['sdf'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'confidence': confidence,
        'cid': cid,
        'sdf': sdf,
      };
}
