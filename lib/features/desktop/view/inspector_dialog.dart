import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/inspector_cubit.dart';
import '../../../core/copy/strings.dart';
import '../../../core/widgets/wiz_sheet.dart';
import 'inspector_body.dart';

/// On a medium window there is no room for the inspector column, so a selection
/// opens the light as a dialog instead (spec §10.9). Closing it clears the
/// selection, so the card it was opened from stops reading as selected.
///
/// The sheet is titled for the panel rather than for the light (P82). The body
/// already carries the light's name as its own heading, live off its bloc, so a
/// title read from the repository would both say the name twice and go on saying
/// the old one after a rename inside the dialog.
///
/// An id that names nothing needs no guard here: the body's bloc reports it gone
/// as it subscribes, which clears the selection, which is what the listener
/// below closes on — so a stale selection still goes, and without a repository
/// read to catch it first.
Future<void> showInspectorDialog(
  BuildContext context, {
  required String lightId,
}) async {
  var inspector = context.read<InspectorCubit>();
  // Cleared the moment the sheet's future completes, which is what stops the
  // clear at the end of this function — a dismissal's own tidying up — from
  // reading as a light that went and asking for a second pop.
  var open = true;
  await showWizSheet<void>(
    context,
    title: Strings.inspector,
    // The body is a scroll view of its own, so it takes the sheet's bounded
    // height rather than being wrapped in a second one.
    scrollable: false,
    builder: (context) => BlocListener<InspectorCubit, String?>(
      // The cubit is carried in rather than looked up: the sheet is a root
      // navigator route, whose overlay need not sit under whatever provided it.
      bloc: inspector,
      listenWhen: (a, b) => open && a == lightId && b != lightId,
      // Only while this sheet is the route on top. The flag above closes when
      // the future completes, but a pop merely *starts* the exit animation and
      // the body goes on listening for the length of it — a home switch, or the
      // light disappearing inside that window, would otherwise pop the route
      // underneath this one.
      listener: (context, _) {
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          Navigator.of(context).pop();
        }
      },
      child: InspectorBody(key: ValueKey(lightId), lightId: lightId),
    ),
  );
  open = false;
  if (inspector.state == lightId) inspector.clear();
}
