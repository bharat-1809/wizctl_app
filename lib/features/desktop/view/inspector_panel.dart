import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/inspector_cubit.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_breakpoints.dart';
import '../../../core/layout/wiz_layout.dart';
import '../../../core/theme/wiz_textures.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_empty_state.dart';
import 'inspector_body.dart';

/// The inspector column (spec §10.9): 352 wide, 400 on a wide window; the
/// selected light, or "No light selected".
///
/// Mounted by `DesktopShell` for the width classes that have room for it
/// (`WidthClass.hasInspectorColumn`); a medium window opens
/// `showInspectorDialog` instead. It reads the *window's* width class from the
/// one `WizLayoutScope` above the router — nothing re-scopes inside the shell.
class InspectorPanel extends StatelessWidget {
  const InspectorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var wide = context.layout.widthClass == WidthClass.wide;
    var selected = context.watch<InspectorCubit>().state;
    return Container(
      width: wide ? wiz.space.inspectorWide : wiz.space.inspector,
      decoration: BoxDecoration(
        gradient: wizVertical(wiz.colors.char900, wiz.colors.char950),
        // `WizCtl_Desktop.dc.html` line 347, `box-shadow: inset 1px 0 0`: the
        // column is parted from the content by a hairline, not a shadow.
        border: Border(
          left: BorderSide(
            color: wiz.colors.edgeHairline,
            width: wiz.space.hairline,
          ),
        ),
      ),
      // Line 347, `padding: 22px 24px`.
      padding: EdgeInsets.symmetric(
        horizontal: wiz.space.s8,
        vertical: wiz.space.s7 + wiz.space.s1,
      ),
      child: selected == null
          ? const Center(
              child: WizEmptyState(
                icon: WizIcons.lightbulb,
                title: Strings.noLightSelected,
                body: Strings.pickALight,
              ),
            )
          : InspectorBody(key: ValueKey(selected), lightId: selected),
    );
  }
}
