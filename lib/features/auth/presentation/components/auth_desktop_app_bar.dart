import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:window_manager/window_manager.dart';

class AuthDesktopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? trailing;

  const AuthDesktopAppBar({super.key, this.trailing});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return DragToMoveArea(
      child: Container(
        height: 80,
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.only(left: 40, right: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/pngs/zedu_logo.png',
              width: 83,
              height: 31,
            ),
            const Spacer(),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 24),
            ],
            if (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.windows ||
                    defaultTargetPlatform == TargetPlatform.macOS ||
                    defaultTargetPlatform == TargetPlatform.linux))
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  WindowCaptionButton.minimize(
                    brightness: Brightness.light, // Dark icons for white background
                    onPressed: () async => await windowManager.minimize(),
                  ),
                  WindowCaptionButton.maximize(
                    brightness: Brightness.light,
                    onPressed: () async {
                      if (await windowManager.isMaximized()) {
                        await windowManager.unmaximize();
                      } else {
                        await windowManager.maximize();
                      }
                    },
                  ),
                  WindowCaptionButton.close(
                    brightness: Brightness.light,
                    onPressed: () async => await windowManager.close(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
