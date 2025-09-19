import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '/theme/app_colors.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final Color? backgroundColor;
  final bool navigateToHistoryOnTap;

  const CommonAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.backgroundColor,
    this.navigateToHistoryOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.primaryDark,
      elevation: 0,
      automaticallyImplyLeading: showBackButton,
      title: GestureDetector(
        onTap: navigateToHistoryOnTap ? () => context.go('/history') : null,
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/images/app_bar_icon.svg',
              height: 32,
              width: 32,
            ),
            if (title != null) ...[
              const SizedBox(width: 12),
              Text(
                title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
