import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/util/plural.dart';
import '../../../core/widgets/wiz_list_row.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/light_repository.dart';
import '../../../domain/repositories/room_repository.dart';

/// "Apply scenes to": the whole home, each room with its count, each light
/// indented with its address; the selection ringed (spec §10.5).
Future<ModeTarget?> showTargetSheet(
  BuildContext context, {
  required String homeId,
  required ModeTarget current,
}) async {
  // Both repositories are read before either await, so no lookup crosses one.
  var roomRepository = context.read<RoomRepository>();
  var lightRepository = context.read<LightRepository>();
  var rooms = await roomRepository.getByHome(homeId);
  var lights = await lightRepository.getByHome(homeId);
  if (!context.mounted) return null;
  var navigator = Navigator.of(context, rootNavigator: true);
  var space = context.wiz.space;
  return showWizSheet<ModeTarget>(
    context,
    title: Strings.applyScenesTo,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WizListRow(
          icon: WizIcons.house,
          title: Strings.wholeHome,
          meta: plural(lights.length, 'light'),
          active: current is WholeHomeTarget,
          onTap: () => navigator.pop(WholeHomeTarget(homeId)),
        ),
        for (var room in rooms) ...[
          SizedBox(height: space.s3),
          WizListRow(
            icon: WizIcons.byName(room.glyph.iconName)!,
            title: room.name,
            meta: plural(
              lights.where((l) => l.roomId == room.id).length,
              'light',
            ),
            active: current == RoomTarget(room.id),
            onTap: () => navigator.pop(RoomTarget(room.id)),
          ),
          for (var light in lights.where((l) => l.roomId == room.id)) ...[
            SizedBox(height: space.s3),
            Padding(
              padding: EdgeInsets.only(left: space.s7),
              child: WizListRow(
                icon: WizIcons.byName(light.fixture.iconName)!,
                title: light.name,
                meta: light.ip,
                active: current == LightTarget(light.id),
                onTap: () => navigator.pop(LightTarget(light.id)),
              ),
            ),
          ],
        ],
      ],
    ),
  );
}
