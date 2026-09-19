import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

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
