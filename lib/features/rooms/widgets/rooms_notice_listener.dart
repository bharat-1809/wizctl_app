import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/notice_listener.dart';
import '../../../core/copy/strings.dart';
import '../../../core/widgets/toast_controller.dart';
import '../bloc/rooms_list_bloc.dart';
import '../bloc/rooms_list_event.dart';
import '../bloc/rooms_list_state.dart';

/// "Room saved" and the odd error, as toasts.
class RoomsNoticeListener extends StatelessWidget {
  final Widget child;
  const RoomsNoticeListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return NoticeListener<RoomsListBloc, RoomsListState, RoomsNotice>(
      noticeOf: (state) => state.notice,
      onNotice: (context, notice) {
        var toasts = context.read<ToastController>();
        switch (notice) {
          case RoomSavedNotice(:var name):
            toasts.push(
              tone: WizToastTone.success,
              title: Strings.roomSaved,
              body: Strings.roomIsEmpty(name),
            );
          case RoomsError(:var message):
            toasts.push(tone: WizToastTone.error, title: message);
        }
      },
      clear: (bloc) => bloc.add(const RoomsNoticeCleared()),
      child: child,
    );
  }
}
