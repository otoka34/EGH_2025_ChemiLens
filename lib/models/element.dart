class Element {
  final String name;
  final String symbol;
  final int atomicNumber;
  final bool discovered;

  const Element({
    required this.name,
    required this.symbol,
    required this.atomicNumber,
    this.discovered = false,
  });

  // コピーコンストラクタ (immutableなオブジェクトのプロパティを変更するために使用)
  Element copyWith({
    String? name,
    String? symbol,
    int? atomicNumber,
    bool? discovered,
  }) {
    return Element(
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      atomicNumber: atomicNumber ?? this.atomicNumber,
      discovered: discovered ?? this.discovered,
    );
  }
}