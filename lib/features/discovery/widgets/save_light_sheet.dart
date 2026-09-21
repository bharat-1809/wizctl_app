import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/toast_controller.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_chip.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../core/widgets/wiz_text_field.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/room_repository.dart';
import '../../../domain/usecases/usecases.dart';
import '../../rooms/widgets/add_room_sheet.dart';

/// "Name this light" (spec §10.8): the device's address and class in mono,
/// ALIAS, and ROOM as chips — or a New room chip when the home has none yet.
/// Resolves to the alias and the room, or null on Cancel.
Future<({String alias, String roomId})?> showSaveLightSheet(
  BuildContext context, {
  required DiscoveredDevice device,
  required String homeId,
}) async {
  var rooms = await context.read<RoomRepository>().getByHome(homeId);
  if (!context.mounted) return null;
  var navigator = Navigator.of(context, rootNavigator: true);
  // The typed alias and the picked room as notifiers the footer's key reads;
  // the field's own `TextEditingController` lives in [_SaveLightBody]'s state.
  // `showWizSheet`'s future completes when the pop *starts*, and the body goes
  // on rebuilding — and the field on reading its controller — for the length
  // of the exit animation, so a controller disposed in `whenComplete` here
  // would be used after being disposed (`add_room_sheet.dart` has the same
  // note). Notifiers nothing re-listens to are safe to drop there.
  var alias = ValueNotifier<String>('');
  var picked = ValueNotifier<String?>(rooms.isEmpty ? null : rooms.first.id);
  var roomList = ValueNotifier<List<Room>>(rooms);
  var cls = device.bulbClass?.displayName ?? Strings.unknownClass;
  return showWizSheet<({String alias, String roomId})>(
    context,
    title: Strings.nameThisLight,
    builder: (context) => _SaveLightBody(
      homeId: homeId,
      meta: Strings.ipAndClass(device.ip, cls),
      onAliasChanged: (value) => alias.value = value,
      picked: picked,
      rooms: roomList,
    ),
    footer: [
      WizButton(
        label: Strings.cancel,
        variant: WizButtonVariant.ghost,
        onPressed: navigator.pop,
      ),
      ValueListenableBuilder<String>(
        valueListenable: alias,
        builder: (context, typed, _) => ValueListenableBuilder<String?>(
          valueListenable: picked,
          builder: (context, room, _) => WizButton(
            label: Strings.saveLight,
            variant: WizButtonVariant.primary,
            fullWidth: true,
            enabled: typed.trim().isNotEmpty && room != null,
            // Read at press time, not the values this build closed over: a
            // keystroke or a chip reaches its notifier at once, but the
            // rebuild it asks for lands on the next frame, and a press in
            // between would save the name and the room as they were a moment
            // ago (`add_room_sheet.dart` has the same note).
            onPressed: () {
              var name = alias.value.trim();
              var roomId = picked.value;
              if (name.isEmpty || roomId == null) return;
              navigator.pop((alias: name, roomId: roomId));
            },
          ),
        ),
      ),
    ],
  ).whenComplete(() {
    alias.dispose();
    picked.dispose();
    roomList.dispose();
  });
}

/// The sheet's body, which owns the alias field's controller: its state is
/// disposed with the route, once the sheet has finished leaving.
class _SaveLightBody extends StatefulWidget {
  final String homeId;
  final String meta;
  final ValueChanged<String> onAliasChanged;
  final ValueNotifier<String?> picked;
  final ValueNotifier<List<Room>> rooms;

  const _SaveLightBody({
    required this.homeId,
    required this.meta,
    required this.onAliasChanged,
    required this.picked,
    required this.rooms,
  });

  @override
  State<_SaveLightBody> createState() => _SaveLightBodyState();
}

class _SaveLightBodyState extends State<_SaveLightBody> {
  final TextEditingController _alias = TextEditingController();

  /// The text last reported, so [_report] fires on a change to the text alone
  /// — what `WizTextField.onChanged` would give. A controller listener also
  /// fires for the selection and the composing range, and one of those
  /// arrives after the pop has started, when the notifier it reports to is
  /// already disposed (`add_room_sheet.dart` has the same note).
  String _reported = '';

  @override
  void initState() {
    super.initState();
    _alias.addListener(_report);
  }

  void _report() {
    if (_alias.text == _reported) return;
    _reported = _alias.text;
    widget.onAliasChanged(_alias.text);
  }

  @override
  void dispose() {
    _alias.removeListener(_report);
    _alias.dispose();
    super.dispose();
  }

  /// A home with no rooms yet gets one from here, so a first save does not
  /// have to leave the sheet to make somewhere to put the light.
  Future<void> _newRoom() async {
    var addRoom = context.read<AddRoom>();
    var toasts = context.read<ToastController>();
    var result = await showRoomSheet(
      context,
      title: Strings.newRoom,
      primaryLabel: Strings.createRoom,
    );
    if (result == null) return;
    // Guarded: this key writes straight through the use case with no bloc to
    // catch for it, so an `Object` — a closed database, a channel that went
    // away — would otherwise reach the framework as an unhandled error and the
    // user would see the room sheet close with no new chip and no reason why.
    Room room;
    try {
      room = await addRoom(widget.homeId, result.name, result.glyph);
    } catch (_) {
      toasts.push(tone: WizToastTone.error, title: Strings.roomSaveFailed);
      return;
    }
    // The sheet may have been dismissed while the room was being written, and
    // the notifiers go with it.
    if (!mounted) return;
    widget.rooms.value = [...widget.rooms.value, room];
    widget.picked.value = room.id;
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.meta,
          style: wiz.typography.mono.copyWith(color: wiz.colors.textTertiary),
        ),
        SizedBox(height: wiz.space.s6),
        const FieldLabel(Strings.alias),
        SizedBox(height: wiz.space.s3),
        WizTextField(
          controller: _alias,
          placeholder: Strings.aliasPlaceholder,
          autofocus: true,
        ),
        SizedBox(height: wiz.space.s6),
        const FieldLabel(Strings.room),
        SizedBox(height: wiz.space.s3),
        ValueListenableBuilder<List<Room>>(
          valueListenable: widget.rooms,
          builder: (context, list, _) => ValueListenableBuilder<String?>(
            valueListenable: widget.picked,
            builder: (context, current, _) => Wrap(
              spacing: wiz.space.s3,
              runSpacing: wiz.space.s3,
              children: [
                for (var room in list)
                  WizChip(
                    label: room.name,
                    selected: room.id == current,
                    onTap: () => widget.picked.value = room.id,
                  ),
                if (list.isEmpty)
                  WizChip(
                    label: Strings.newRoom,
                    accentText: true,
                    onTap: _newRoom,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
