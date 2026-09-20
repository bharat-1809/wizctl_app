import 'package:flutter/material.dart';

import '../../../app/widgets/width_switch.dart';
import '../../desktop/view/grid_screen.dart';
import 'room_screen.dart';

/// `/rooms/:roomId`: the phone's Room, or the desktop's grid of that room.
/// Both read the `RoomBloc` the route provides above this, so a resize across
/// the compact boundary swaps the widget and keeps the room, its aggregates
/// and its poll scope.
class RoomPage extends StatelessWidget {
  const RoomPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const WidthSwitch(compact: RoomScreen(), wide: GridScreen.room());
}
