import 'package:flutter/material.dart';
import 'package:team_25_app/theme/app_colors.dart';

class CommonLoading {
  /// 全画面ローディング（主にページ遷移時）
  static Widget fullScreen({String? message, Color? backgroundColor}) {
    return Container(
      color: backgroundColor ?? AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3.0,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// インラインローディング（リスト内やカード内）
  static Widget inline({double size = 20.0, Color? color}) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color ?? AppColors.primary,
        strokeWidth: 2.0,
      ),
    );
  }

  /// ダイアログローディング（API通信時など）
  static Widget dialog({String? message}) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3.0,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ボタン内ローディング
  static Widget button({Color? color, double size = 16.0}) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color ?? Colors.white,
        strokeWidth: 2.0,
      ),
    );
  }

  /// ローディングダイアログを表示
  static void showLoadingDialog(
    BuildContext context, {
    String? message,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => dialog(message: message),
    );
  }

  /// ローディングダイアログを閉じる
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}
