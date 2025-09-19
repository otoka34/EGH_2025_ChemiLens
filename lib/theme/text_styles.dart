import 'package:flutter/material.dart';
import 'package:team_25_app/theme/app_colors.dart';

class AppTextStyles {
  // ヘッダー系
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
    letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ボディテキスト
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // 強調テキスト
  static const TextStyle bodyLargeBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMediumBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // キャプション・補足情報
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static const TextStyle captionBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  // ラベル・UI要素
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.2,
    letterSpacing: 0.2,
  );

  // 特殊用途
  static const TextStyle monospace = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    fontFamily: 'monospace',
    height: 1.4,
  );

  static const TextStyle error = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.red,
    height: 1.4,
  );

  static const TextStyle success = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.green,
    height: 1.4,
  );

  // 説明文専用
  static const Color _descriptionColor = Color(0xFF4A5568);
  static const Color _labelColor = Color(0xFF2D3748);

  // プライマリカラー系
  static TextStyle primaryText({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.4,
  }) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: AppColors.primary,
    height: height,
  );

  static TextStyle secondaryText({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.4,
  }) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: AppColors.textSecondary,
    height: height,
  );

  // ボタンテキスト
  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonTextSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
    letterSpacing: 0.1,
  );

  // リンクテキスト
  static TextStyle linkText({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    bool underline = true,
  }) => TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: AppColors.primary,
    decoration: underline ? TextDecoration.underline : null,
    decorationColor: AppColors.primary,
    height: 1.4,
  );
}

/// コンテキスト別のテキストスタイル拡張
extension TextStyleContext on AppTextStyles {
  // 分子名表示用
  static const TextStyle moleculeName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle moleculeFormula = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    fontFamily: 'monospace',
    height: 1.2,
  );

  static const TextStyle moleculeDescription = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppTextStyles._descriptionColor,
    height: 1.4,
  );

  // 検索結果用
  static const TextStyle searchTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle searchDescription = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppTextStyles._descriptionColor,
    height: 1.5,
  );

  // 履歴用
  static const TextStyle historyTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle historyDate = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    height: 1.2,
  );

  // 詳細画面用
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle infoLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppTextStyles._labelColor,
    height: 1.3,
  );

  static const TextStyle infoValue = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppTextStyles._descriptionColor,
    height: 1.3,
  );
}
