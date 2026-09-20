import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/wiz_breakpoints.dart';
import '../../core/layout/wiz_layout.dart';
import '../../features/desktop/view/inspector_dialog.dart';
import '../../features/desktop/view/inspector_panel.dart';
import '../../features/home/bloc/home_screen_bloc.dart';
import '../../features/home/bloc/home_screen_event.dart';
import '../blocs/homes_bloc.dart';
import '../blocs/homes_state.dart';
import '../blocs/inspector_cubit.dart';
import '../shell_deps.dart';
import 'desktop_rail.dart';

/// The desktop chrome (spec §10.9): the rail, the branch navigator as the
/// content column, and the inspector as a third column on the right for the
/// width classes with room for it (`WidthClass.hasInspectorColumn`). A medium
/// window has no third column, so a selection there opens the inspector as a
/// dialog instead.
///
/// The rail's data is a `HomeScreenBloc` of its own — the room counts and what
/// is lit have to be right on Settings and on Scenes, where no route provides
/// one — which also keeps the whole home polled for as long as the desktop
/// window is up. A route that provides its own shadows this one, so the "All
/// lights" grid still reads the bloc that belongs to `/home`.
///
/// No banners here (P79): every screen places its own inside its scroll, and a
/// copy in the chrome would double them.
class DesktopShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const DesktopShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    // Medium is the one desktop class too narrow for labels beside the glyphs
    // (spec §14): 72 of rail instead of 264.
    var widthClass = context.layout.widthClass;
    var collapsed = widthClass == WidthClass.medium;
    var deps = context.read<ShellDeps>();
    return BlocProvider(
      create: (_) => HomeScreenBloc(
        homes: deps.homes,
        rooms: deps.rooms,
        lights: deps.lights,
        store: deps.store,
        settings: deps.settings,
        setPower: deps.setPower,
        sync: deps.sync,
      )..add(const HomeScreenSubscribed()),
      child: BlocListener<HomesBloc, HomesState>(
        // A light selected in one home names nothing in the next.
        listenWhen: (a, b) => a.activeHomeId != b.activeHomeId,
        listener: (context, _) => context.read<InspectorCubit>().clear(),
        child: BlocListener<InspectorCubit, String?>(
          // Only where there is no column to show it in: the dialog is the
          // medium class's inspector, and it clears the selection when it
          // closes, so the next pick opens it again.
          listenWhen: (a, b) => collapsed && b != null && a != b,
          listener: (context, id) => showInspectorDialog(context, lightId: id!),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DesktopRail(collapsed: collapsed),
              Expanded(child: shell),
              if (widthClass.hasInspectorColumn) const InspectorPanel(),
            ],
          ),
        ),
      ),
    );
  }
}
