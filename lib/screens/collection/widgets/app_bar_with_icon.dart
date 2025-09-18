import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AppBarWithIcon extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWithIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          SvgPicture.asset(
            'assets/images/app_bar_icon.svg',
            height: 32,
            width: 32,
          ),
        ],
      ),
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
