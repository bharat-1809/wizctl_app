import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/blocs/homes_bloc.dart';
import '../../../app/blocs/homes_event.dart';
import '../../../app/blocs/homes_state.dart';
import '../../../app/blocs/settings_cubit.dart';
import '../../../app/routes.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_layout.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/toast_controller.dart';
import '../../../core/widgets/wiz_list_row.dart';
import '../../../core/widgets/wiz_toggle.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/light_repository.dart';
import 'rename_home_sheet.dart';

/// The rows of spec §10.7, in order: the home's name, Discovery on a phone or
/// Config file and CLI parity on a desktop, Re-scan on launch, Sound &
/// haptics.
class SettingsRows extends StatelessWidget {
  const SettingsRows({super.key});

  /// The trailing glyphs (`WizCtl_Mobile.dc.html` line 1239: `icoChevron` is
  /// `chevron-right` at 18, `icoPencil` is `pencil` at 17): the chevron on a
  /// row that leads somewhere, the pencil on the row that opens a sheet.
  static const double chevron = 18;
  static const double pencil = 17;

  Future<void> _rename(BuildContext context, HomesState homes) async {
    var home = homes.activeHome;
    if (home == null) return;
    var bloc = context.read<HomesBloc>();
    var name = await showRenameHomeSheet(context, name: home.name);
    if (name != null) bloc.add(HomeRenamed(home.id, name));
  }

  /// Config file and CLI parity, the two rows only a desktop shows.
  List<Widget> _cliRows(BuildContext context, Home home) {
    var wiz = context.wiz;
    return [
      WizListRow(
        icon: WizIcons.terminal,
        title: Strings.configFile,
        meta: Strings.configFilePath,
      ),
      // The kit row's meta is one ellipsised line, so the sentence spec §10.7
      // puts under the path is its own caption rather than a newline inside
      // the meta, which the row would clip away.
      SizedBox(height: wiz.space.s2),
      Text(
        Strings.configFileNote,
        style: wiz.typography.bodySm.copyWith(color: wiz.colors.textTertiary),
      ),
      SizedBox(height: wiz.space.s3),
      _CliParityRow(homeId: home.id),
    ];
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var desktop = context.layout.widthClass.isDesktopLike;
    var cubit = context.read<SettingsCubit>();
    var settings = context.watch<SettingsCubit>().state;
    var homes = context.watch<HomesBloc>().state;
    var home = homes.activeHome;
    var gap = SizedBox(height: wiz.space.s3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (home != null)
          WizListRow(
            icon: WizIcons.house,
            title: home.name,
            meta: Strings.homeName,
            trailing: WizIcon(
              WizIcons.pencil,
              size: pencil,
              color: wiz.colors.textTertiary,
            ),
            onTap: () => _rename(context, homes),
          ),
        if (!desktop) ...[
          gap,
          WizListRow(
            icon: WizIcons.radio,
            title: Strings.discovery,
            meta: Strings.discoveryMeta,
            trailing: WizIcon(
              WizIcons.chevronRight,
              size: chevron,
              color: wiz.colors.textTertiary,
            ),
            onTap: () => context.go(AppRoutes.discover),
          ),
        ] else if (home != null) ...[
          gap,
          ..._cliRows(context, home),
        ],
        gap,
        WizListRow(
          icon: WizIcons.refreshCw,
          title: Strings.rescanOnLaunch,
          trailing: WizToggle(
            value: settings.rescanOnLaunch,
            size: WizToggleSize.sm,
            onChanged: cubit.setRescanOnLaunch,
            semanticsLabel: Strings.rescanOnLaunch,
          ),
        ),
        gap,
        WizListRow(
          icon: WizIcons.zap,
          title: Strings.soundAndHaptics,
          meta: desktop ? Strings.clicksOnly : Strings.clicksAndVibration,
          trailing: WizToggle(
            value: settings.feedbackEnabled,
            size: WizToggleSize.sm,
            onChanged: cubit.setFeedback,
            semanticsLabel: Strings.soundAndHaptics,
          ),
        ),
      ],
    );
  }
}

/// The CLI-parity row: the command `wizctl` would take for this home's first
/// light, copied to the clipboard on a tap (spec §10.7).
///
/// Its own widget because the light has to be read before the meta can be
/// written, and the read belongs to the row's state: a `FutureBuilder` handed
/// a future built in `build` starts a fresh read on every rebuild of the
/// screen — a toggle is enough — and drops its meta back to the fallback for
/// the frame in between.
class _CliParityRow extends StatefulWidget {
  final String homeId;

  const _CliParityRow({required this.homeId});

  @override
  State<_CliParityRow> createState() => _CliParityRowState();
}

class _CliParityRowState extends State<_CliParityRow> {
  late Future<List<Light>> _lights = _read();

  Future<List<Light>> _read() =>
      context.read<LightRepository>().getByHome(widget.homeId);

  @override
  void didUpdateWidget(_CliParityRow old) {
    super.didUpdateWidget(old);
    if (old.homeId != widget.homeId) _lights = _read();
  }

  /// Copies the command and says so: spec §10.7 asks only that the tap copy,
  /// and a copy with no acknowledgement leaves the user nothing to go on.
  Future<void> _copy(String name) async {
    var toasts = context.read<ToastController>();
    await Clipboard.setData(ClipboardData(text: Strings.cliCommand(name)));
    toasts.push(tone: WizToastTone.info, title: Strings.copied);
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return FutureBuilder<List<Light>>(
      future: _lights,
      builder: (context, snapshot) {
        // A home with no lights yet: the whole-home target is what the CLI
        // takes when nothing can be named.
        var name = snapshot.data?.firstOrNull?.name ?? Strings.wholeHome;
        return WizListRow(
          icon: WizIcons.terminal,
          title: Strings.cliParity,
          meta: Strings.cliCommand(name),
          trailing: WizIcon(
            WizIcons.chevronRight,
            size: SettingsRows.chevron,
            color: wiz.colors.textTertiary,
          ),
          onTap: () => _copy(name),
        );
      },
    );
  }
}
