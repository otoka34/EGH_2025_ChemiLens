import 'package:flutter/material.dart';
import 'package:team_25_app/models/element.dart' as my_element;
import 'package:team_25_app/screens/encyclopedia/widgets/element_card.dart';

class ElementGrid extends StatelessWidget {
  final List<my_element.Element> elements;
  final Function(int index) onElementTap;
  final double childAspectRatio; // <-- 追加

  const ElementGrid({
    super.key,
    required this.elements,
    required this.onElementTap,
    this.childAspectRatio = 1.0, // <-- デフォルト値を設定 (図鑑ページ用)
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount( // const を削除
          crossAxisCount: 4,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: childAspectRatio, // <-- プロパティを使用
        ),
        itemCount: elements.length,
        itemBuilder: (context, index) {
          final element = elements[index];
          return ElementCard(
            name: element.name,
            symbol: element.symbol,
            atomicNumber: element.atomicNumber,
            discovered: element.discovered,
            onTap: () => onElementTap(index),
          );
        },
      ),
    );
  }
}
