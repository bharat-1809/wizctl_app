import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';

/// An outer emission glow that fades in and out over the light duration.
/// Stack it behind a surface of the same shape.
class WizGlow extends StatefulWidget {
  final bool on;
  final List<BoxShadow> shadows;
  final BorderRadius radius;

  const WizGlow({
    super.key,
    required this.on,
    required this.shadows,
    required this.radius,
  });

  @override
  State<WizGlow> createState() => _WizGlowState();
}

class _WizGlowState extends State<WizGlow> with SingleTickerProviderStateMixin {
  // Built in didChangeDependencies, never as a field initialiser: its
  // duration comes from context.wiz.motion, and an InheritedWidget lookup
  // like that isn't safe before the element has established dependencies.
  AnimationController? _controller;
  Animation<double>? _opacity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var motion = context.wiz.motion;
    var controller = _controller;
    if (controller == null) {
      controller = _controller = AnimationController(
        vsync: this,
        duration: motion.light,
        value: widget.on ? 1 : 0,
      );
      _opacity = CurvedAnimation(parent: controller, curve: motion.tactile);
    } else {
      controller.duration = motion.light;
    }
  }

  @override
  void didUpdateWidget(covariant WizGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.on != oldWidget.on) {
      if (widget.on) {
        _controller!.forward();
      } else {
        _controller!.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: _opacity!,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.radius,
            boxShadow: widget.shadows,
          ),
        ),
      ),
    );
  }
}
