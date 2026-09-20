import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/inspector_cubit.dart';
import '../../../app/shell_deps.dart';
import '../../../app/widgets/width_switch.dart';
import '../../desktop/view/grid_screen.dart';
import '../../rooms/bloc/room_bloc.dart';
import '../../rooms/bloc/room_event.dart';
import '../bloc/light_bloc.dart';
import '../widgets/light_notice_listener.dart';
import 'light_screen.dart';

/// `/lights/:id` (spec §9): the detail screen on a phone; on wider widths the
/// light's own room, with the light selected in the inspector.
///
/// A desktop window has no detail screen — the inspector column *is* the detail
/// view, and it is already on show — so the route's job there is to put the
/// light in it and show the room it belongs to behind it. The location stays
/// `/lights/<id>`, which is what a Back from the phone reading pops, and what a
/// deep link or a shared window arrives on.
class LightPage extends StatelessWidget {
  const LightPage({super.key});

  @override
  Widget build(BuildContext context) => const WidthSwitch(
    compact: LightNoticeListener(child: LightScreen()),
    wide: _LightOnDesktop(),
  );
}

/// Selects the route's light into the inspector, then draws its room's grid.
///
/// A `StatefulWidget` because the selection happens once, when the route is
/// mounted, and not again on every rebuild: a click on another card in the grid
/// below moves the selection, and a route that re-asserted its own would fight
/// it. The cubit is written after the first frame rather than in `initState` —
/// the inspector column is a sibling of this page in the shell's `Row`, and
/// marking a sibling dirty from inside a build is what the framework refuses
/// (`LightScreen`'s own `_LeaveWhenGone` defers for the same reason).
class _LightOnDesktop extends StatefulWidget {
  const _LightOnDesktop();

  @override
  State<_LightOnDesktop> createState() => _LightOnDesktopState();
}

class _LightOnDesktopState extends State<_LightOnDesktop> {
  @override
  void initState() {
    super.initState();
    var lightId = context.read<LightBloc>().lightId;
    var inspector = context.read<InspectorCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) inspector.select(lightId);
    });
  }

  @override
  Widget build(BuildContext context) {
    var roomId = context.select<LightBloc, String?>(
      (b) => b.state.light?.roomId,
    );
    // Nothing yet, or an id that names no light: the rail is still there, so an
    // empty content column is a dead end nobody is stuck in, and the inspector
    // says "No light selected" for the same id beside it.
    if (roomId == null) return const SizedBox.shrink();
    var deps = context.read<ShellDeps>();
    return BlocProvider(
      key: ValueKey(roomId),
      create: (_) => RoomBloc(
        roomId: roomId,
        rooms: deps.rooms,
        lights: deps.lights,
        store: deps.store,
        setPower: deps.setPower,
        setBrightness: deps.setBrightness,
        setKelvin: deps.setKelvin,
        sync: deps.sync,
      )..add(const RoomSubscribed()),
      child: const GridScreen.room(),
    );
  }
}
