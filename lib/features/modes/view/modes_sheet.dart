import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../core/copy/strings.dart';
import '../../../core/layout/wiz_layout.dart';
import '../../../core/widgets/toast_controller.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../domain/entities/entities.dart';
import '../bloc/light_modes_bloc.dart';
import '../bloc/light_modes_event.dart';
import '../bloc/light_modes_state.dart';
import '../widgets/modes_body.dart';
import '../widgets/modes_layout.dart';
import '../widgets/modes_notice_listener.dart';

/// The modes sheet for a room or a light (spec §10.3, §10.4, §10.5): a
/// bottom sheet on a phone, a 680 dialog elsewhere. Owns its bloc for as
/// long as it is up. [blocFor] builds one for the target; the caller has
/// the use cases.
///
/// The title names the target ("Light mode · `<room>`"), which the bloc reads
/// from the repositories; the sheet waits for the bloc's first ready state
/// (a few microtasks) so the title is right from the first frame.
Future<void> showModesSheet(
  BuildContext context, {
  required ModeTarget target,
  required LightModesBloc Function(ModeTarget target) blocFor,
}) async {
  // Carried into the route, not read from it: the sheet is pushed on the root
  // navigator, whose overlay sits above whatever provided the queue, so the
  // listener inside the body would not find it there. Read before the await,
  // so no lookup crosses it.
  var toasts = context.read<ToastController>();
  var bloc = blocFor(target)..add(const ModesSubscribed());
  if (bloc.state.status != ModesStatus.ready) {
    await bloc.stream.firstWhere((s) => s.status == ModesStatus.ready);
  }
  if (!context.mounted) {
    await bloc.close();
    return;
  }
  var layout = context.layout.widthClass.isCompact
      ? ModesLayout.sheet
      : ModesLayout.dialog;
  await showWizSheet<void>(
    context,
    title: _title(bloc.state),
    maxWidth: layout.maxWidth,
    builder: (context) => ChangeNotifierProvider<ToastController>.value(
      value: toasts,
      child: BlocProvider.value(
        value: bloc,
        child: ModesNoticeListener(child: ModesBody(layout: layout)),
      ),
    ),
  ).whenComplete(bloc.close);
}

/// "Light mode · whole home" / "· `<room>`" / "· `<light>`".
String _title(LightModesState state) {
  if (state.target is WholeHomeTarget) return Strings.lightModeWholeHome;
  var name = state.targetName;
  return name == null ? Strings.lightMode : Strings.lightModeFor(name);
}
