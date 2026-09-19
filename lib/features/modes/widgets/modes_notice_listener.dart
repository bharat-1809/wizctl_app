import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/notice_listener.dart';
import '../../../core/copy/strings.dart';
import '../../../core/widgets/toast_controller.dart';
import '../../../domain/entities/entities.dart';
import '../bloc/light_modes_bloc.dart';
import '../bloc/light_modes_event.dart';
import '../bloc/light_modes_state.dart';

/// The modes toasts (spec §5.12): "`<Scene>` applied", and the three
/// nothing-eligible errors.
class ModesNoticeListener extends StatelessWidget {
  final Widget child;
  const ModesNoticeListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return NoticeListener<LightModesBloc, LightModesState, ModesNotice>(
      noticeOf: (state) => state.notice,
      onNotice: (context, notice) {
        var toasts = context.read<ToastController>();
        switch (notice) {
          case SceneAppliedNotice(:var sceneName, :var target, :var targetName):
            toasts.push(
              tone: WizToastTone.success,
              title: Strings.sceneApplied(sceneName),
              // On the target, not on a null name: a room or light deleted
              // under the sheet yields a null name too, and that is not the
              // whole home (`SceneAppliedNotice`'s own doc).
              body: target is WholeHomeTarget
                  ? Strings.toWholeHome
                  : targetName == null
                  ? null
                  : Strings.toTarget(targetName),
            );
          case NoColourNotice():
            toasts.push(
              tone: WizToastTone.error,
              title: Strings.noColourBulb,
              body: Strings.colourNeedsRgb,
            );
          case NoWhiteNotice():
            toasts.push(
              tone: WizToastTone.error,
              title: Strings.noWhiteChannel,
              body: Strings.bulbsOnlyDim,
            );
          case NoSceneNotice():
            toasts.push(
              tone: WizToastTone.error,
              title: Strings.noSceneChannel,
              body: Strings.plugOnlySwitches,
            );
        }
      },
      clear: (bloc) => bloc.add(const ModesNoticeCleared()),
      child: child,
    );
  }
}
