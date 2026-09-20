import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/copy/strings.dart';
import '../core/icons/wiz_icon_data.dart';
import '../core/theme/wiz_theme.dart';
import '../core/widgets/toast_controller.dart';
import '../core/widgets/wiz_icon_key.dart';
import '../features/gallery/gallery_screen.dart';

/// The widget gallery behind the Settings row (debug builds only, spec §18):
/// the Plan 2 screen with a back key floating in the top-left, since the
/// gallery has no bar of its own.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return Stack(
      children: [
        GalleryScreen(toasts: context.read<ToastController>()),
        Positioned(
          top: MediaQuery.paddingOf(context).top + space.s4,
          left: space.s4,
          child: WizIconKey(
            icon: WizIcons.chevronLeft,
            semanticsLabel: Strings.back,
            onPressed: () => context.pop(),
          ),
        ),
      ],
    );
  }
}
