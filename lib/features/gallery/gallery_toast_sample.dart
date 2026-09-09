import 'package:flutter/material.dart';

import '../../core/widgets/toast_controller.dart';
import '../../core/widgets/wiz_toast.dart';

/// The toast card itself, shown inline so the gallery has one standing still:
/// a queued toast takes itself away after 3.2 s, which is no use for judging
/// it. [WizToastLayer] stacks this same widget.
class GalleryToastSample extends StatelessWidget {
  const GalleryToastSample({super.key});

  @override
  Widget build(BuildContext context) {
    return const WizToast(
      data: WizToastData(
        id: 'gallery-sample',
        tone: WizToastTone.success,
        title: 'Cozy applied',
        body: 'to the whole home',
      ),
    );
  }
}
