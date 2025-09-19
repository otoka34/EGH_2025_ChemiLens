import 'package:flutter/material.dart';
import 'package:team_25_app/theme/app_colors.dart';
import 'package:team_25_app/theme/text_styles.dart';
import 'package:team_25_app/widgets/base/base_card.dart';

class MoleculeCard extends StatelessWidget {
  final String name;
  final String description;
  final String? formula;
  final Widget? actionButton;
  final VoidCallback? onTap;

  const MoleculeCard({
    super.key,
    required this.name,
    required this.description,
    this.formula,
    this.actionButton,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 分子アイコン
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.science_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // 分子情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                if (formula != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    formula!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyleContext.moleculeDescription,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          if (actionButton != null) ...[
            const SizedBox(width: 12),
            actionButton!,
          ],
        ],
      ),
    );
  }
}
