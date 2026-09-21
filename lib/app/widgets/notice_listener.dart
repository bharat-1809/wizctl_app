import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Acts on a bloc's one-shot notice and then clears it.
///
/// Every feature bloc reports what the user has to be told — a toast, a
/// navigation — as a nullable `notice` on its state, and every view that
/// carries one needs the same three lines: listen while the notice changes
/// to something, act on it, tell the bloc to drop it. That boilerplate
/// lives here once; a feature's own listener keeps only the `switch` over
/// its notice type.
///
/// [noticeOf] reads the notice off the state, [onNotice] acts on it, and
/// [clear] hands the bloc whichever "notice cleared" event it takes. The
/// notice has to be cleared, or the next equal one would not read as a
/// change and would never fire.
class NoticeListener<B extends StateStreamable<S>, S, N extends Object>
    extends StatelessWidget {
  /// The notice on [S], or null when there is nothing to act on.
  final N? Function(S state) noticeOf;

  /// What the notice means for the view: a toast, a route, both.
  final void Function(BuildContext context, N notice) onNotice;

  /// Drops the notice, e.g. `(bloc) => bloc.add(const HomesNoticeCleared())`.
  final void Function(B bloc) clear;

  final Widget? child;

  const NoticeListener({
    super.key,
    required this.noticeOf,
    required this.onNotice,
    required this.clear,
    this.child,
  });

  @override
  Widget build(BuildContext context) => BlocListener<B, S>(
    listenWhen: (a, b) => noticeOf(b) != null && noticeOf(a) != noticeOf(b),
    listener: (context, state) {
      onNotice(context, noticeOf(state)!);
      clear(context.read<B>());
    },
    child: child,
  );
}
