import 'package:flutter/material.dart';

import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_sheet.dart';

/// "Forget `<name>`?" (spec §10.4). Resolves to true only on Forget: Cancel
/// and a dismissal both pop with null, which is a no.
Future<bool> showForgetLightSheet(
  BuildContext context, {
  required String name,
}) async {
  var navigator = Navigator.of(context, rootNavigator: true);
  var sure = await showWizSheet<bool>(
    context,
    title: Strings.forgetTitle(name),
    builder: (context) => Text(
      Strings.forgetBody,
      style: context.wiz.typography.body.copyWith(
        color: context.wiz.colors.textSecondary,
      ),
    ),
    footer: [
      WizButton(
        label: Strings.cancel,
        variant: WizButtonVariant.ghost,
        onPressed: navigator.pop,
      ),
      WizButton(
        label: Strings.forget,
        variant: WizButtonVariant.danger,
        fullWidth: true,
        onPressed: () => navigator.pop(true),
      ),
    ],
  );
  return sure ?? false;
}
