import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wizctl/wizctl.dart';

import '../../../app/widgets/blink_key.dart';
import '../../../app/widgets/field_label.dart';
import '../../../app/widgets/fixture_kind.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_chip.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_text_field.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/usecases/usecases.dart';
import '../../rooms/widgets/add_room_sheet.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';

/// One kept light on step 3 of the first run (spec §10.1): its address and
/// flash key, the alias field, the ROOM chips with New room, and SHOW IT AS.
class AssignCard extends StatefulWidget {
  final FoundDevice row;
  final Assignment assignment;
  final List<OnboardingRoom> rooms;

  const AssignCard({
    super.key,
    required this.row,
    required this.assignment,
    required this.rooms,
  });

  @override
  State<AssignCard> createState() => _AssignCardState();
}

class _AssignCardState extends State<AssignCard> {
  /// Seeded from the assignment the card is built with and never re-seeded:
  /// every later change to that alias came from this field.
  late final TextEditingController _alias = TextEditingController(
    text: widget.assignment.alias,
  );

  @override
  void dispose() {
    _alias.dispose();
    super.dispose();
  }

  Future<void> _newRoom(BuildContext context, OnboardingBloc bloc) async {
    var result = await showRoomSheet(
      context,
      title: Strings.newRoom,
      primaryLabel: Strings.createRoom,
    );
    if (result == null) return;
    // The light whose card opened the sheet lands in the room just made.
    bloc.add(
      OnboardingRoomAdded(
        result.name,
        result.glyph,
        forIp: widget.row.device.ip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<OnboardingBloc>();
    var device = widget.row.device;
    var ip = device.ip;
    var cls = device.bulbClass?.displayName ?? Strings.unknownClass;
    return WizPanel(
      padding: EdgeInsets.all(wiz.space.s7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  Strings.ipAndClass(ip, cls),
                  style: wiz.typography.mono.copyWith(
                    color: wiz.colors.textTertiary,
                  ),
                ),
              ),
              BlinkKey(ip: ip, bulbClass: device.bulbClass),
            ],
          ),
          SizedBox(height: wiz.space.s5),
          WizTextField(
            controller: _alias,
            height: wiz.space.controlLg,
            placeholder: device.bulbClass == BulbClass.socket
                ? Strings.plugPlaceholder
                : Strings.bulbPlaceholder,
            onChanged: (v) => bloc.add(OnboardingAliasChanged(ip, v)),
          ),
          SizedBox(height: wiz.space.s6),
          const FieldLabel(Strings.room),
          SizedBox(height: wiz.space.s3),
          Wrap(
            spacing: wiz.space.s3,
            runSpacing: wiz.space.s3,
            children: [
              for (var room in widget.rooms)
                WizChip(
                  label: room.name,
                  selected: room.tempId == widget.assignment.roomTempId,
                  onTap: () => bloc.add(OnboardingRoomPicked(ip, room.tempId)),
                ),
              WizChip(
                label: Strings.newRoom,
                icon: WizIcons.plus,
                accentText: true,
                onTap: () => _newRoom(context, bloc),
              ),
            ],
          ),
          SizedBox(height: wiz.space.s6),
          const FieldLabel(Strings.showItAs),
          SizedBox(height: wiz.space.s3),
          Wrap(
            spacing: wiz.space.s3,
            runSpacing: wiz.space.s3,
            children: [
              for (var fixture in Fixture.values)
                WizIconKey(
                  icon: WizIcons.byName(fixture.iconName)!,
                  shape: WizKeyShape.squircle,
                  active: fixture == widget.assignment.fixture,
                  // The copy layer's word for the shape, not the domain's own
                  // `Fixture.label` (P66).
                  semanticsLabel: fixtureLabelOf(fixture),
                  onPressed: () =>
                      bloc.add(OnboardingFixturePicked(ip, fixture)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
