import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/navigation.dart';
import '../../../app/widgets/notice_listener.dart';
import '../../../core/copy/strings.dart';
import '../../../core/widgets/toast_controller.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_event.dart';
import '../bloc/light_state.dart';

/// Acts on [LightBloc] notices: a forgotten light toasts and leaves the
/// screen; an error toasts.
///
/// [navigate] is false for the desktop inspector (spec §10.9), which shares the
/// bloc's notices but not the screen's exit: there is nothing to pop beside a
/// column, and the location is already the room the light was in. The toast is
/// pushed either way.
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
  final bool navigate;

  const LightNoticeListener({
    super.key,
    required this.child,
    this.navigate = true,
  });

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
            if (navigate) {
              popOr(
                context,
                lightParent(context.read<LightBloc>().state.light?.roomId),
              );
            }
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
