import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../navigation.dart';

/// Leaves a screen whose subject has gone (P63), exactly once.
///
/// A `BlocListener` on its own is not enough. A stale route, or a deep link to
/// an id that no longer names anything, reaches the gone state *before* this
/// widget is mounted, and a listener never fires for the state a bloc is
/// already in — the reader would be stranded in a blank body, which has no bar
/// and so no Back. The state on hand is therefore checked once after the first
/// frame, which is the earliest point a route may be replaced, and on every
/// state after that.
///
/// [isGone] reads the screen's own gone status. [parent] names where to go when
/// nothing is beneath to pop to. [standDown] is for a screen that has a second
/// way out for the same state — the Light screen's forget flow toasts and
/// leaves through its notice listener — and it still consumes this widget's
/// one-shot, so that between the two of them exactly one navigation happens
/// even if another gone state were ever to follow.
class LeaveWhenGone<B extends StateStreamable<S>, S> extends StatefulWidget {
  final bool Function(S state) isGone;
  final String Function(S state) parent;
  final bool Function(S state)? standDown;
  final Widget child;

  const LeaveWhenGone({
    super.key,
    required this.isGone,
    required this.parent,
    this.standDown,
    required this.child,
  });

  @override
  State<LeaveWhenGone<B, S>> createState() => _LeaveWhenGoneState<B, S>();
}

class _LeaveWhenGoneState<B extends StateStreamable<S>, S>
    extends State<LeaveWhenGone<B, S>> {
  bool _left = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onState(context.read<B>().state);
    });
  }

  void _onState(S state) {
    if (_left || !widget.isGone(state)) return;
    _left = true;
    if (widget.standDown?.call(state) ?? false) return;
    popOr(context, widget.parent(state));
  }

  @override
  Widget build(BuildContext context) => BlocListener<B, S>(
    listener: (context, state) => _onState(state),
    child: widget.child,
  );
}
