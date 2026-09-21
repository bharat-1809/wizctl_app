import 'package:flutter/material.dart';

import '../../../app/widgets/width_switch.dart';
import '../../desktop/view/grid_screen.dart';
import 'home_screen.dart';

/// `/home`: the phone's Home, or the desktop's "All lights" grid. Both read
/// the `HomeScreenBloc` the route provides above this, so a resize across the
/// compact boundary swaps the widget and keeps the data, the poll scope and
/// the bloc.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) =>
      const WidthSwitch(compact: HomeScreen(), wide: GridScreen.allLights());
}
