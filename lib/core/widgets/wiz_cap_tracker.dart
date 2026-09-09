import 'package:flutter/widgets.dart';

/// Measures keyed items after layout so a single raised cap can travel to
/// the active one. The cap is one element that moves; nothing cross-fades.
mixin WizCapTracker<T extends StatefulWidget> on State<T> {
  final GlobalKey containerKey = GlobalKey();
  final Map<Object, GlobalKey> _itemKeys = {};
  Rect? capRect;

  GlobalKey keyFor(Object value) => _itemKeys.putIfAbsent(value, GlobalKey.new);

  /// Schedule a measurement for after this frame. Safe to call from build:
  /// it only calls setState when the rect actually changed.
  ///
  /// Called from inside a [LayoutBuilder] so a resize — which relays out
  /// without rebuilding — re-measures too.
  void measureCap(Object? active) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var container = containerKey.currentContext?.findRenderObject();
      var item = active == null
          ? null
          : _itemKeys[active]?.currentContext?.findRenderObject();
      if (container is! RenderBox ||
          item is! RenderBox ||
          !item.hasSize ||
          !container.hasSize) {
        if (capRect != null) setState(() => capRect = null);
        return;
      }
      var offset = item.localToGlobal(Offset.zero, ancestor: container);
      var rect = offset & item.size;
      if (rect != capRect) setState(() => capRect = rect);
    });
  }
}
