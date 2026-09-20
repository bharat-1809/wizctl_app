import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/inspector_cubit.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../domain/repositories/light_repository.dart';
import 'inspector_body.dart';

/// On a medium window there is no room for the inspector column, so a selection
/// opens the light as a dialog instead (spec §10.9). Closing it clears the
/// selection, so the card it was opened from stops reading as selected.
///
/// The light's name is read here, before the sheet is pushed, because the sheet
/// wants it as its title and the body's own bloc does not exist until the sheet
/// is on screen (`showTargetSheet` reads the repository the same way). An id
/// that names nothing opens nothing and takes the stale selection with it.
Future<void> showInspectorDialog(
  BuildContext context, {
  required String lightId,
}) async {
  var inspector = context.read<InspectorCubit>();
  var light = await context.read<LightRepository>().get(lightId);
  if (!context.mounted) return;
  if (light == null) {
    inspector.clear();
    return;
  }
  // True while the sheet's route is up. [InspectorBody] clears the selection
  // when its light goes, which on a medium window is also the cue to close —
  // but a dismissal clears the selection too, from the line below, and a pop
  // then would take whatever is underneath with it.
  var open = true;
  await showWizSheet<void>(
    context,
    title: light.name,
    // The body is a scroll view of its own, so it takes the sheet's bounded
    // height rather than being wrapped in a second one.
    scrollable: false,
    builder: (context) => BlocListener<InspectorCubit, String?>(
      // The cubit is carried in rather than looked up: the sheet is a root
      // navigator route, whose overlay need not sit under whatever provided it.
      bloc: inspector,
      listenWhen: (a, b) => open && a == lightId && b != lightId,
      listener: (context, _) => Navigator.of(context).pop(),
      child: InspectorBody(key: ValueKey(lightId), lightId: lightId),
    ),
  );
  open = false;
  if (inspector.state == lightId) inspector.clear();
}
