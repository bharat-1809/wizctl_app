import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/navigation.dart';
import '../../../app/widgets/notice_listener.dart';
import '../../../core/copy/strings.dart';
import '../../../core/widgets/toast_controller.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_event.dart';
import '../bloc/light_state.dart';
import '../view/light_screen.dart';

/// Acts on [LightBloc] notices: a forgotten light toasts and leaves the
/// screen; an error toasts.
///
/// The forgotten notice is **not** cleared. It arrives on the same state as
/// [LightStatus.gone], and clearing it would leave `{gone, notice: null}`
/// behind — which is indistinguishable from a light removed somewhere else,
/// and would send the screen's own gone-leave after this one. The screen is
/// on its way out and its bloc goes with the route, so there is nothing left
/// to clear. An error is cleared as usual, or the next equal one would not
/// read as a change.
class LightNoticeListener extends StatelessWidget {
  final Widget child;
  const LightNoticeListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return NoticeListener<LightBloc, LightState, LightNotice>(
      noticeOf: (state) => state.notice,
      onNotice: (context, notice) {
        var toasts = context.read<ToastController>();
        switch (notice) {
          case LightForgottenNotice(:var name):
            toasts.push(
              tone: WizToastTone.success,
              title: Strings.forgotten(name),
              body: Strings.removedFromConfig,
            );
            popOr(
              context,
              lightScreenParent(context.read<LightBloc>().state.light?.roomId),
            );
          case LightError(:var message):
            toasts.push(tone: WizToastTone.error, title: message);
        }
      },
      clear: (bloc) {
        if (bloc.state.notice is LightError) {
          bloc.add(const LightNoticeCleared());
        }
      },
      child: child,
    );
  }
}
