import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/blocs/inspector_cubit.dart';
import '../../../app/navigation.dart';
import '../../../app/shell_deps.dart';
import '../../../app/widgets/width_switch.dart';
import '../../desktop/view/grid_screen.dart';
import '../../rooms/bloc/room_bloc.dart';
import '../../rooms/bloc/room_event.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_state.dart';
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

/// Selects the route's light into the inspector, draws its room's grid, and
/// leaves when the light has gone.
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
  /// Set by the one leave this route makes, so a second `gone` cannot repeat it.
  bool _left = false;

  @override
  void initState() {
    super.initState();
    var bloc = context.read<LightBloc>();
    var inspector = context.read<InspectorCubit>();
    // Deferred for the sibling column, and it is also the earliest point a
    // route may be replaced — which makes it the right place to catch a light
    // that had already gone before this page was built (a stale deep link):
    // a listener never fires for the state a bloc is already in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      inspector.select(bloc.lightId);
      _onState(bloc.state);
    });
  }

  /// Leaves for the light's own room, or Home when there is no room to name,
  /// the first time this route's light has gone (P83).
  ///
  /// The desktop reading has no detail screen to strand the reader on, but it
  /// does have a location, and `/lights/<id>` naming a light that no longer
  /// exists is not one. This is the *only* navigator on this reading: the
  /// inspector's `LightNoticeListener` is built with `navigate: false`, so a
  /// forget from the column toasts there and leaves from here, exactly once.
  void _onState(LightState state) {
    if (_left || state.status != LightStatus.gone) return;
    _left = true;
    // The last light seen, which a forget keeps so that it can still name its
    // room; an id that never named one leaves it null and falls back to Home.
    context.go(lightParent(state.light?.roomId));
  }

  @override
  Widget build(BuildContext context) {
    var roomId = context.select<LightBloc, String?>(
      (b) => b.state.light?.roomId,
    );
    return BlocListener<LightBloc, LightState>(
      listener: (context, state) => _onState(state),
      // Nothing on screen while the first read is in flight, and for the one
      // frame a light that has gone takes to leave through [_onState].
      child: roomId == null ? const SizedBox.shrink() : _room(context, roomId),
    );
  }

  Widget _room(BuildContext context, String roomId) {
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
