import 'package:flutter/material.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../core/widgets/wiz_text_field.dart';

/// "Rename light": ALIAS, Cancel / Save alias (spec §10.4, §10.9).
/// Resolves to the trimmed alias, or null on Cancel and on a dismissal.
/// Save alias is out of reach while the field is blank.
Future<String?> showRenameLightSheet(
  BuildContext context, {
  required String name,
}) {
  var navigator = Navigator.of(context, rootNavigator: true);
  // The typed alias as a notifier the footer's key reads, with the field's own
  // `TextEditingController` down in [_AliasField]'s state: `showWizSheet`'s
  // future completes when the pop *starts*, and the body goes on rebuilding —
  // and the field on reading its controller — for the length of the exit
  // animation, so a controller disposed in `whenComplete` here would be used
  // after being disposed (`add_room_sheet.dart` has the same note). A notifier
  // nothing re-listens to is safe to drop there.
  var alias = ValueNotifier<String>(name);
  return showWizSheet<String>(
    context,
    title: Strings.renameLight,
    builder: (context) =>
        _AliasField(initial: name, onChanged: (v) => alias.value = v),
    footer: [
      WizButton(
        label: Strings.cancel,
        variant: WizButtonVariant.ghost,
        onPressed: navigator.pop,
      ),
      ValueListenableBuilder<String>(
        valueListenable: alias,
        builder: (context, value, _) => WizButton(
          label: Strings.saveAlias,
          variant: WizButtonVariant.primary,
          fullWidth: true,
          enabled: value.trim().isNotEmpty,
          // Read at press time, not the [value] this build closed over: a
          // keystroke reaches the notifier at once, but the rebuild it asks
          // for lands on the next frame, and a press in between would save
          // the alias as it was a keystroke ago.
          onPressed: () => navigator.pop(alias.value.trim()),
        ),
      ),
    ],
  ).whenComplete(alias.dispose);
}

/// The sheet's body, which owns the field's controller so that it is disposed
/// with the route rather than when the pop begins.
class _AliasField extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onChanged;

  const _AliasField({required this.initial, required this.onChanged});

  @override
  State<_AliasField> createState() => _AliasFieldState();
}

class _AliasFieldState extends State<_AliasField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      const FieldLabel(Strings.alias),
      SizedBox(height: context.wiz.space.s3),
      WizTextField(
        controller: _controller,
        placeholder: Strings.aliasPlaceholder,
        autofocus: true,
        // `onChanged`, not a controller listener: a listener also fires for
        // the selection and the composing range, and `EditableText` clears
        // the composing region when the field loses focus — which happens
        // after the pop has started, when the notifier is already disposed.
        onChanged: widget.onChanged,
      ),
    ],
  );
}
