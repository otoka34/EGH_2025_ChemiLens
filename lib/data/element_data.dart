import 'package:team_25_app/models/element.dart';

class ElementData {
  static List<Element> get allElements => const [
    Element(name: '水素', symbol: 'H', atomicNumber: 1, discovered: true),
    Element(name: 'ホウ素', symbol: 'B', atomicNumber: 2, discovered: true),
    Element(name: '炭素', symbol: 'C', atomicNumber: 3, discovered: false),
    Element(name: '窒素', symbol: 'N', atomicNumber: 4, discovered: false),
    Element(name: '酸素', symbol: 'O', atomicNumber: 5, discovered: true),
    Element(name: 'フッ素', symbol: 'F', atomicNumber: 6, discovered: true),
    Element(name: 'ナトリウム', symbol: 'Na', atomicNumber: 7, discovered: true),
    Element(name: 'マグネシウム', symbol: 'Mg', atomicNumber: 8, discovered: true),
    Element(name: 'アルミニウム', symbol: 'Al', atomicNumber: 9, discovered: true),
    Element(name: 'ケイ素', symbol: 'Si', atomicNumber: 10, discovered: false),
    Element(name: 'リン', symbol: 'P', atomicNumber: 11, discovered: true),
    Element(name: '硫黄', symbol: 'S', atomicNumber: 12, discovered: true),
    Element(name: '塩素', symbol: 'Cl', atomicNumber: 13, discovered: true),
    Element(name: 'カリウム', symbol: 'K', atomicNumber: 14, discovered: true),
    Element(name: 'カルシウム', symbol: 'Ca', atomicNumber: 15, discovered: true),
    Element(name: 'ヨウ素', symbol: 'I', atomicNumber: 16, discovered: false),
  ];
}
