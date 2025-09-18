import 'package:flutter/material.dart';

class HistoryDateHeader extends StatelessWidget {
  final String dateLabel;

  const HistoryDateHeader({super.key, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            dateLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A), // アプリのメインカラー
            ),
          ),
        ),
        // 太い境界線
        Container(
          height: 3,
          width: double.infinity,
          color: Colors.grey[300],
          margin: const EdgeInsets.only(bottom: 12),
        ),
      ],
    );
  }
}
