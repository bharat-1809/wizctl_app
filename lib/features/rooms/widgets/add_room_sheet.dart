import 'package:flutter/material.dart';

import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../domain/entities/entities.dart';
import 'room_form.dart';

/// A room sheet: "Add a room" (spec §10.6), "New room" (spec §10.1) and
/// "Rename room" are the same form with different titles, keys and
/// starting values. Resolves to the name and glyph, or null on Cancel.
/// The primary key is disabled until the name is non-blank.
Future<({String name, RoomGlyph glyph})?> showRoomSheet(
  BuildContext context, {
  required String title,
  required String primaryLabel,
  String initialName = '',
  RoomGlyph? initialGlyph = RoomGlyph.sofa,
  bool showNote = false,
}) {
  var navigator = Navigator.of(context, rootNavigator: true);
  // The typed name as a notifier the footer's key reads, and the field's own
  // `TextEditingController` down in [_RoomSheetBody]'s state: `showWizSheet`'s
  // future completes when the pop *starts*, and the body goes on rebuilding —
  // and the field on reading its controller — for the length of the exit
  // animation, so a controller disposed in `whenComplete` here is used after
  // being disposed (`homes_sheet.dart` has the same note). A notifier nothing
  // re-listens to is safe to drop there; the controller belongs to the state
  // that outlives the pop.
  var name = ValueNotifier<String>(initialName);
  var glyph = ValueNotifier<RoomGlyph>(initialGlyph ?? RoomGlyph.sofa);
  return showWizSheet<({String name, RoomGlyph glyph})>(
    context,
    title: title,
    builder: (context) => _RoomSheetBody(
      initialName: initialName,
      onNameChanged: (value) => name.value = value,
      glyph: glyph,
      // A rename keeps the room's glyph, so it shows the name field alone.
      showGlyph: initialGlyph != null,
      showNote: showNote,
    ),
    footer: [
      WizButton(
        label: Strings.cancel,
        variant: WizButtonVariant.ghost,
        onPressed: navigator.pop,
      ),
      ValueListenableBuilder<String>(
        valueListenable: name,
        builder: (context, value, _) => WizButton(
          label: primaryLabel,
          variant: WizButtonVariant.primary,
          fullWidth: true,
          enabled: value.trim().isNotEmpty,
          // Read at press time, not the [value] this build closed over: a
          // keystroke reaches the notifier at once, but the rebuild it asks
          // for lands on the next frame, and a press in between would save
          // the name as it was a keystroke ago.
          onPressed: () =>
              navigator.pop((name: name.value.trim(), glyph: glyph.value)),
        ),
      ),
    ],
  ).whenComplete(() {
    name.dispose();
    glyph.dispose();
  });
}

/// The sheet's body, which owns the name field's controller: its state is
/// disposed with the route, once the sheet has finished leaving.
class _RoomSheetBody extends StatefulWidget {
  final String initialName;
  final ValueChanged<String> onNameChanged;
  final ValueNotifier<RoomGlyph> glyph;
  final bool showGlyph;
  final bool showNote;

  const _RoomSheetBody({
    required this.initialName,
    required this.onNameChanged,
    required this.glyph,
    required this.showGlyph,
    required this.showNote,
  });

  @override
  State<_RoomSheetBody> createState() => _RoomSheetBodyState();
}

class _RoomSheetBodyState extends State<_RoomSheetBody> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );

  /// The text last reported, so [_report] fires on a change to the text
  /// alone — what `WizTextField.onChanged` would give. A controller listener
  /// also fires for the selection and the composing range, and one of those
  /// (`EditableText` clears the composing region when the field loses focus)
  /// arrives after the pop has started, when the notifier it reports to is
  /// already disposed.
  late String _reported = widget.initialName;

  @override
  void initState() {
    super.initState();
    _name.addListener(_report);
  }

  void _report() {
    if (_name.text == _reported) return;
    _reported = _name.text;
    widget.onNameChanged(_name.text);
  }

  @override
  void dispose() {
    _name.removeListener(_report);
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<RoomGlyph>(
    valueListenable: widget.glyph,
    builder: (context, value, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RoomForm(
          controller: _name,
          glyph: widget.showGlyph ? value : null,
          onGlyph: (g) => widget.glyph.value = g,
        ),
        if (widget.showNote) ...[
          SizedBox(height: context.wiz.space.s6),
          WizPanel(
            variant: WizPanelVariant.inset,
            child: Text(
              Strings.roomsStored,
              style: context.wiz.typography.bodySm.copyWith(
                color: context.wiz.colors.textTertiary,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
