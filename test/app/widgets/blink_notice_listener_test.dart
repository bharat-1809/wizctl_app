import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/blocs/blink_cubit.dart';
import 'package:wizctl_app/app/widgets/blink_notice_listener.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';

import '../../support/fakes.dart';
import '../../support/wiz_test_app.dart';

/// The bulb the blink is aimed at.
const String _ip = '192.168.1.115';

void main() {
  /// Builds the cubit, the queue and the listener over them, runs [body] and
  /// closes them — inside the tester's body, as every fixture here is.
  Future<void> withListener(
    WidgetTester tester,
    Future<void> Function(BlinkCubit cubit, ToastController toasts) body, {
    DeviceFailure? failing,
  }) async {
    var gateway = FakeGateway();
    gateway.states[_ip] = const LightState(isOn: false);
    if (failing != null) gateway.failing[_ip] = failing;
    var cubit = BlinkCubit(
      blink: BlinkLight(gateway: gateway, clock: FakeClock()),
    );
    var toasts = ToastController();
    try {
      await tester.pumpWidget(
        wizTestApp(
          BlocProvider.value(
            value: cubit,
            child: ChangeNotifierProvider<ToastController>.value(
              value: toasts,
              child: const BlinkNoticeListener(child: SizedBox.shrink()),
            ),
          ),
        ),
      );
      await body(cubit, toasts);
    } finally {
      await cubit.close();
      toasts.dispose();
    }
  }

  testWidgets('a blink that answers says nothing', (tester) async {
    await withListener(tester, (cubit, toasts) async {
      await cubit.blink(_ip);
      await tester.pump();
      expect(toasts.toasts, isEmpty);
    });
  });

  testWidgets('a blink that times out toasts once and clears the failure', (
    tester,
  ) async {
    await withListener(tester, failing: const TimeoutFailure(_ip, 3), (
      cubit,
      toasts,
    ) async {
      await cubit.blink(_ip);
      await tester.pump();
      expect(toasts.toasts, hasLength(1));
      expect(toasts.toasts.single.title, Strings.noResponseAfterTries);
      expect(toasts.toasts.single.body, Strings.didNotAnswer(_ip));
      expect(
        cubit.state.failure,
        isNull,
        reason:
            'cleared, or the next failure on the same bulb is not a '
            'change and never fires',
      );

      // The same bulb again: a failure that was cleared reads as new.
      await cubit.blink(_ip);
      await tester.pump();
      expect(toasts.toasts, hasLength(2));
    });
  });
}
