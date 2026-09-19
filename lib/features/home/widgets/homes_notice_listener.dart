import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/blocs/homes_bloc.dart';
import '../../../app/blocs/homes_event.dart';
import '../../../app/blocs/homes_state.dart';
import '../../../app/routes.dart';
import '../../../app/widgets/notice_listener.dart';
import '../../../core/copy/strings.dart';
import '../../../core/widgets/toast_controller.dart';

/// Acts on [HomesBloc] notices wherever the Homes sheet can be opened: a new
/// home toasts and goes to discovery (spec §10.2); an error toasts.
class HomesNoticeListener extends StatelessWidget {
  final Widget child;
  const HomesNoticeListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return NoticeListener<HomesBloc, HomesState, HomesNotice>(
      noticeOf: (state) => state.notice,
      onNotice: (context, notice) {
        var toasts = context.read<ToastController>();
        switch (notice) {
          case HomeCreatedNotice(:var home):
            toasts.push(
              tone: WizToastTone.success,
              title: Strings.homeCreated(home.name),
              body: Strings.discoverOnNetwork,
            );
            context.go(AppRoutes.discover);
          case HomesError(:var message):
            toasts.push(tone: WizToastTone.error, title: message);
        }
      },
      clear: (bloc) => bloc.add(const HomesNoticeCleared()),
      child: child,
    );
  }
}
