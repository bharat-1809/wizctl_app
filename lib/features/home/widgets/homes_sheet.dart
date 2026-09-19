import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/blocs/homes_bloc.dart';
import '../../../app/blocs/homes_event.dart';
import '../../../app/blocs/homes_state.dart';
import '../../../app/routes.dart';
import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_list_row.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../../../core/widgets/wiz_text_field.dart';

/// The Homes sheet (spec §10.2): one row per home, the active one marked,
/// a field for a new one. Tapping a row switches and closes; Add home is
/// enabled once the field has a name (the sheet disables the key rather
/// than playing reject on press, because the primary key already plays
/// confirm on pointer down).
Future<void> showHomesSheet(BuildContext context) {
  var bloc = context.read<HomesBloc>();
  var router = GoRouter.of(context);
  var navigator = Navigator.of(context, rootNavigator: true);
  // The typed name, rather than a `TextEditingController` shared between the
  // field in the body and the key in the footer. `showWizSheet`'s future
  // completes when the pop *starts*, and the field goes on rebuilding — and
  // re-listening to its controller — for the length of the exit animation,
  // so a controller disposed there is used after being disposed. A notifier
  // the field only writes to has no such listener.
  var name = ValueNotifier<String>('');
  return showWizSheet<void>(
    context,
    title: Strings.homes,
    builder: (context) => BlocProvider.value(
      value: bloc,
      child: _HomesSheetBody(
        onNameChanged: (value) => name.value = value,
        onPick: (id) {
          bloc.add(HomeSwitched(id));
          navigator.pop();
          router.go(AppRoutes.home);
        },
      ),
    ),
    footer: [
      WizButton(
        label: Strings.close,
        variant: WizButtonVariant.ghost,
        onPressed: navigator.pop,
      ),
      ValueListenableBuilder<String>(
        valueListenable: name,
        builder: (context, value, _) => WizButton(
          label: Strings.addHome,
          variant: WizButtonVariant.primary,
          fullWidth: true,
          enabled: value.trim().isNotEmpty,
          onPressed: () {
            bloc.add(HomeCreated(value));
            navigator.pop();
          },
        ),
      ),
    ],
  ).whenComplete(name.dispose);
}

class _HomesSheetBody extends StatelessWidget {
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onPick;
  const _HomesSheetBody({required this.onNameChanged, required this.onPick});

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return BlocBuilder<HomesBloc, HomesState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var h in state.homes) ...[
            WizListRow(
              icon: WizIcons.house,
              title: h.home.name,
              meta: Strings.roomsAndLights(h.roomCount, h.lightCount),
              active: h.home.id == state.activeHomeId,
              onTap: () => onPick(h.home.id),
            ),
            SizedBox(height: space.s3),
          ],
          SizedBox(height: space.s4),
          const FieldLabel(Strings.newHome),
          SizedBox(height: space.s3),
          WizTextField(
            placeholder: Strings.newHomePlaceholder,
            onChanged: onNameChanged,
          ),
        ],
      ),
    );
  }
}
