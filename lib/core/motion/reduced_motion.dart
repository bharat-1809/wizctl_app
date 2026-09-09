import 'package:flutter/widgets.dart';

/// Honour the system "reduce motion" setting: staggers, breathe and other
/// decorative motion are skipped; state changes still snap (spec §12,
/// "all skipped under reduced motion").
///
/// The one place the platform switch is read, so a widget that has to stop
/// a loop rather than merely freeze what it paints reads the same thing
/// everything else does. Read it inside `didChangeDependencies` or `build`,
/// where the dependency is registered and the switch flipping rebuilds.
bool wizReducedMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);
