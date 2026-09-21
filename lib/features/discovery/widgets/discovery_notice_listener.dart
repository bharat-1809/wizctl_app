import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/widgets/toast_controller.dart';
import '../bloc/discovery_bloc.dart';
import '../bloc/discovery_event.dart';
import '../bloc/discovery_state.dart';

/// "Saving `<alias>`" while a save runs, resolved in place to "`<alias>`
/// saved" or to a failure naming the same light (spec §15).
///
/// Stateful, and so a raw `BlocListener` rather than `NoticeListener` (P3):
/// the loading toast's id has to outlive one build, and the alias with it,
/// because `SaveFailedNotice` carries only a message. The `listenWhen` keeps
/// `NoticeListener`'s rule for the notice and adds the saves in flight, and
/// the notice is cleared after acting, exactly as the shared listener does.
class DiscoveryNoticeListener extends StatefulWidget {
  final Widget child;
  const DiscoveryNoticeListener({super.key, required this.child});

  @override
  State<DiscoveryNoticeListener> createState() =>
      _DiscoveryNoticeListenerState();
}

class _DiscoveryNoticeListenerState extends State<DiscoveryNoticeListener> {
  /// The loading toast raised for each save in flight, by the address being
  /// saved, with the alias the user gave it.
  final Map<String, ({String id, String alias})> _saving = {};

  /// The controller to clean up against, taken while the element is still
  /// active: an inherited lookup from [dispose] is too late, because the
  /// element is already defunct by then.
  ToastController? _toasts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _toasts = context.read<ToastController>();
  }

  @override
  void dispose() {
    // A save still in flight when the screen leaves would strand its loading
    // toast: a loading toast never times out — it waits to be resolved — and
    // the controller is app-scoped, so it would sit on every screen after
    // this one. The write itself is not cancelled; it simply has nobody left
    // to report to.
    for (var save in _saving.values) {
      _toasts?.dismiss(save.id);
    }
    _saving.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiscoveryBloc, DiscoveryState>(
      listenWhen: (a, b) =>
          a.saving != b.saving || (b.notice != null && a.notice != b.notice),
      listener: (context, state) {
        var toasts = context.read<ToastController>();
        for (var entry in state.saving.entries) {
          _saving[entry.key] ??= (
            id: toasts.push(
              tone: WizToastTone.loading,
              title: Strings.saving(entry.value),
            ),
            alias: entry.value,
          );
        }
        switch (state.notice) {
          case LightSavedNotice(:var alias, :var ip):
            var pending = _saving.remove(ip);
            var title = Strings.aliasSaved(alias);
            var body = Strings.addedToHome(ip);
            if (pending == null) {
              toasts.push(tone: WizToastTone.success, title: title, body: body);
            } else {
              toasts.update(
                pending.id,
                tone: WizToastTone.success,
                title: title,
                body: body,
              );
            }
          case SaveFailedNotice(:var message):
            // The message is user-ready only when the domain refused the save;
            // for anything else it is the raw error. Either way it is the body
            // under copy of our own, never a title on its own.
            var pending = _saving.values.toList();
            _saving.clear();
            for (var save in pending) {
              toasts.update(
                save.id,
                tone: WizToastTone.error,
                title: Strings.couldNotSave(save.alias),
                body: message,
              );
            }
            if (pending.isEmpty) {
              toasts.push(
                tone: WizToastTone.error,
                title: Strings.saveFailed,
                body: message,
              );
            }
          case null:
            break;
        }
        if (state.notice != null) {
          context.read<DiscoveryBloc>().add(const DiscoveryNoticeCleared());
        }
      },
      child: widget.child,
    );
  }
}
