import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// A recessed well the user types into. No border; the well shadow is the
/// edge. Focus draws the amber ring.
class WizTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final double? height;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool enabled;
  final TextStyle? style;

  const WizTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.height,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.enabled = true,
    this.style,
  });

  @override
  State<WizTextField> createState() => _WizTextFieldState();
}

class _WizTextFieldState extends State<WizTextField> {
  /// A plain field initialiser is right here: unlike an animation
  /// controller, a focus node takes nothing from `context.wiz`.
  final FocusNode _focus = FocusNode(debugLabel: 'WizTextField');

  /// Focus ring thickness, design system §11.2 ("Focus: 2 px amber ring").
  static const double _focusRingWidth = 2;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var style =
        widget.style ?? wiz.typography.bodyLg.copyWith(color: c.textPrimary);
    return WizSurface(
      spec: wiz.elevation.well,
      radius: BorderRadius.circular(wiz.space.r3),
      color: c.char1000,
      height: widget.height ?? wiz.space.controlMd,
      glow: _focus.hasFocus
          ? [BoxShadow(color: c.focusRing, spreadRadius: _focusRingWidth)]
          : const [],
      padding: EdgeInsets.symmetric(horizontal: wiz.space.s6),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textInputAction: widget.textInputAction,
        style: style,
        cursorColor: c.amber400,
        scrollPadding: EdgeInsets.all(wiz.space.s12),
        decoration: InputDecoration.collapsed(
          hintText: widget.placeholder,
          hintStyle: style.copyWith(color: c.textTertiary),
        ),
      ),
    );
  }
}
