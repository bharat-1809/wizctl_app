import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

/// Back: pops when this screen was pushed onto something, and otherwise goes
/// to [fallback] — the screen's natural parent — so a deep link opened cold
/// still has somewhere to go back to.
void popOr(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

/// A light's natural parent: its own room, or Home when there is no room to go
/// back to — an id that no longer names a light has no room either. Back, a
/// light that has gone and the forgotten notice all leave the Light screen
/// through this one door, so it is written once, here beside [popOr].
String lightParent(String? roomId) =>
    roomId == null ? AppRoutes.home : AppRoutes.room(roomId);
