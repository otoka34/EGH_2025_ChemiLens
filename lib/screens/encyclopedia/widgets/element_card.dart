import 'package:flutter/material.dart';

class ElementCard extends StatelessWidget {
  final String name;
  final String symbol;
  final int atomicNumber;
  final bool discovered;
  final VoidCallback? onTap; // タップイベントを追加

  const ElementCard({
    super.key,
    required this.name,
    required this.symbol,
    required this.atomicNumber,
    this.discovered = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDiscovered = discovered;

    // カードの背景色とボーダー色
    Color cardBackgroundColor;
    Color cardBorderColor;
    Color symbolColor;
    Color nameColor;
    Color numberBackgroundColor;
    Color numberColor;

    if (isDiscovered) {
      cardBackgroundColor = const Color(0xFFE8F8FF); // discovered
      cardBorderColor = const Color(0xFF53CBF6); // discovered
      symbolColor = const Color(0xFF2B7FC7); // discovered .element-symbol
      nameColor = const Color(0xFF1E6BA8); // discovered .element-name
      numberBackgroundColor = const Color(
        0xFF53CBF6,
      ).withValues(alpha: 0.2); // discovered .element-number background
      numberColor = const Color(0xFF2B7FC7); // discovered .element-number color
    } else {
      cardBackgroundColor = const Color(0xFFF5F5F5); // undiscovered
      cardBorderColor = const Color(0xFFBDBDBD); // undiscovered
      symbolColor = const Color(0xFFBDBDBD); // undiscovered .element-symbol
      nameColor = const Color(0xFF9E9E9E); // undiscovered .element-name
      numberBackgroundColor = const Color(
        0xFF000000,
      ).withValues(alpha: 0.1); // default .element-number background
      numberColor = const Color(0xFF666666); // default .element-number color
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero, // 親のGridViewでpaddingを制御するため
        color: cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: cardBorderColor, width: 2),
        ),
        elevation: 0, // HTMLのbox-shadowは親で制御
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: numberBackgroundColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$atomicNumber', // 常に原子番号を表示
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: numberColor,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    symbol,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600, // <-- w700 から w600 に変更
                      color: symbolColor,
                      fontFamily: 'Fredoka', // <-- ここにFredokaフォントを追加
                    ),
                  ),
                  Text(
                    name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: nameColor,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
