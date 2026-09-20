import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/widgets/notice_listener.dart';
import '../../../core/copy/strings.dart';
import '../../../core/widgets/toast_controller.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';

/// Acts on [OnboardingBloc]'s notices (spec §10.1): a finished first run
/// toasts "`<Home>` is set up" over "`<n>` lights in `<m>` rooms" and goes to
/// Home; a refused one toasts why and leaves the flow where it stands, with
/// Finish offered again.
class OnboardingNoticeListener extends StatelessWidget {
  final Widget child;
  const OnboardingNoticeListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return NoticeListener<OnboardingBloc, OnboardingState, OnboardingNotice>(
      noticeOf: (state) => state.notice,
      onNotice: (context, notice) {
        var toasts = context.read<ToastController>();
        switch (notice) {
          case OnboardingDone(:var home, :var lightCount, :var roomCount):
            toasts.push(
              tone: WizToastTone.success,
              title: Strings.homeSetUp(home.name),
              body: Strings.lightsInRooms(lightCount, roomCount),
            );
            context.go(AppRoutes.home);
          case OnboardingError(:var message):
            toasts.push(tone: WizToastTone.error, title: message);
        }
      },
      clear: (bloc) => bloc.add(const OnboardingNoticeCleared()),
      child: child,
    );
  }
}
