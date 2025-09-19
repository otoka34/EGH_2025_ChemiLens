import 'package:flutter/material.dart';
import 'package:team_25_app/theme/app_colors.dart';
import 'package:team_25_app/widgets/base/base_card.dart';

class ImageCard extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ImageCard({
    super.key,
    this.imageUrl,
    this.height = 200,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: imageUrl != null
              ? Image.network(
                  imageUrl!,
                  fit: fit,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return placeholder ??
                        Container(
                          color: AppColors.background,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return errorWidget ??
                        Container(
                          color: AppColors.background,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                  },
                )
              : Container(
                  color: AppColors.background,
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
