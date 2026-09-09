import 'package:flutter/foundation.dart';

import '../domain/entities/debug_flags.dart';

/// The prototype switches' state. Only debug builds ever change it.
class DebugFlagsHolder extends ValueNotifier<DebugFlags> {
  DebugFlagsHolder() : super(DebugFlags.none);
}
