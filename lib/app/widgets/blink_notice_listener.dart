import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/copy/strings.dart';
import '../../core/widgets/toast_controller.dart';
import '../blocs/blink_cubit.dart';
import '../blocs/blink_state.dart';
import 'notice_listener.dart';

/// A blink that could not read or restore its bulb shows the command-timeout
/// toast (spec §5.10). There is nothing to retry: the restore is one-shot, and
/// the bulb is either back where it was or was never reached at all.
///
/// Mounted once by the shell rather than by each screen: the blink key is on
/// every card, and the cubit is app-scope.
class BlinkNoticeListener extends StatelessWidget {
  final Widget child;

  const BlinkNoticeListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return NoticeListener<BlinkCubit, BlinkState, BlinkFailure>(
      noticeOf: (state) => state.failure,
      onNotice: (context, failure) => context.read<ToastController>().push(
        tone: WizToastTone.error,
        title: Strings.noResponseAfterTries,
        body: Strings.didNotAnswer(failure.ip),
      ),
      clear: (cubit) => cubit.clearFailure(),
      child: child,
    );
  }
}
