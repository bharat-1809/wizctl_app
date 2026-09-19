import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/command_toasts.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/widgets/toast_controller.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/device_command_pipeline.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';

import '../support/fakes.dart';

const _delay = Duration(milliseconds: 600);

Light _light(String id, String ip) => Light(
  id: id,
  homeId: 'h',
  roomId: 'r',
  name: 'Bedside bulb $id',
  ip: ip,
  mac: id,
  bulbClass: BulbClass.rgb,
  fixture: Fixture.bulb,
  addedAt: DateTime(2026),
);

CommandItem _item(Light light) => CommandItem(
  light: light,
  signal: ControlSignal(state: true),
  patch: (s) => s.copyWith(isOn: true),
);

/// A whole pipeline over the fakes, so the listener is tested against the
/// reports the real one emits rather than a hand-written sequence.
class _Rig {
  final gateway = FakeGateway();
  final store = LiveStateStore();
  final lights = FakeLightRepository();
  final toasts = ToastController();
  late final NetworkMonitor network;
  late final DeviceCommandPipeline pipeline;
  late final CommandToastListener listener;
  String? homeSubnet = '192.168.1';

  _Rig({String? current = '192.168.1'}) {
    network = NetworkMonitor(FakeNetworkInfo(current));
    pipeline = DeviceCommandPipeline(
      gateway: gateway,
      store: store,
      network: network,
      homeSubnet: () async => homeSubnet,
      clock: FakeClock(),
      ids: SequenceIds(),
    );
    listener = CommandToastListener(
      toasts: toasts,
      pipeline: pipeline,
      lights: lights,
      delay: _delay,
    );
  }

  void dispose() {
    listener.dispose();
    pipeline.dispose();
    toasts.dispose();
    store.dispose();
  }
}

void main() {
  test('a write that finishes quickly never shows a toast', () {
    fakeAsync((async) {
      var rig = _Rig();
      var a = _light('a', '192.168.1.115');
      rig.lights.seed([a]);
      unawaited(rig.network.refresh());
      async.flushMicrotasks();
      rig.listener.start();

      unawaited(rig.pipeline.run(CommandBatch(items: [_item(a)])));
      async.flushMicrotasks();
      expect(rig.toasts.toasts, isEmpty);
      async.elapse(_delay * 2);
      expect(
        rig.toasts.toasts,
        isEmpty,
        reason: 'success dismissed the armed toast',
      );
      rig.dispose();
    });
  });

  test(
    'a slow single-light write shows the loading toast with its address',
    () {
      fakeAsync((async) {
        var rig = _Rig();
        var a = _light('a', '192.168.1.115');
        rig.lights.seed([a]);
        rig.gateway.sendLatency = const Duration(seconds: 2);
        unawaited(rig.network.refresh());
        async.flushMicrotasks();
        rig.listener.start();

        unawaited(rig.pipeline.run(CommandBatch(items: [_item(a)])));
        async.elapse(_delay - const Duration(milliseconds: 1));
        expect(rig.toasts.toasts, isEmpty);
        async.elapse(const Duration(milliseconds: 2));
        var toast = rig.toasts.toasts.single;
        expect(toast.tone, WizToastTone.loading);
        expect(toast.title, 'Sending to Bedside bulb a');
        expect(toast.body, '192.168.1.115:38899');
        async.elapse(const Duration(seconds: 2));
        expect(rig.toasts.toasts, isEmpty, reason: 'resolved in place: gone');
        rig.dispose();
      });
    },
  );

  test('a failed write resolves the toast to the error with Retry', () {
    fakeAsync((async) {
      var rig = _Rig();
      var a = _light('a', '192.168.1.115');
      rig.lights.seed([a]);
      rig.gateway.failing[a.ip] = const TimeoutFailure('192.168.1.115', 3);
      unawaited(rig.network.refresh());
      async.flushMicrotasks();
      rig.listener.start();

      unawaited(rig.pipeline.run(CommandBatch(items: [_item(a)])));
      async.flushMicrotasks();
      var toast = rig.toasts.toasts.single;
      expect(toast.tone, WizToastTone.error);
      expect(toast.title, Strings.noResponseAfterTries);
      expect(toast.body, '192.168.1.115 did not answer on port 38899');
      expect(toast.actionLabel, Strings.retry);

      // Retry: the loading toast is pushed synchronously by the action, so
      // it is observable before the microtasks that finish the retry run.
      toast.onAction!();
      expect(rig.toasts.toasts.single.tone, WizToastTone.loading);
      expect(rig.toasts.toasts.single.title, 'Retrying Bedside bulb a');
      // Still failing → "Still no reply".
      async.flushMicrotasks();
      var again = rig.toasts.toasts.single;
      expect(again.tone, WizToastTone.error);
      expect(again.title, Strings.stillNoReply);
      expect(again.body, Strings.checkWallSwitch);
      expect(again.actionLabel, isNull);
      rig.dispose();
    });
  });

  test('a retry that succeeds takes the toast away', () {
    fakeAsync((async) {
      var rig = _Rig();
      var a = _light('a', '192.168.1.115');
      rig.lights.seed([a]);
      rig.gateway.failing[a.ip] = const TimeoutFailure('192.168.1.115', 3);
      unawaited(rig.network.refresh());
      async.flushMicrotasks();
      rig.listener.start();

      unawaited(rig.pipeline.run(CommandBatch(items: [_item(a)])));
      async.flushMicrotasks();
      rig.gateway.failing.remove(a.ip);
      rig.toasts.toasts.single.onAction!();
      async.flushMicrotasks();
      async.flushMicrotasks();
      expect(rig.toasts.toasts, isEmpty);
      rig.dispose();
    });
  });

  test('every failed light of a batch gets its own error toast', () {
    fakeAsync((async) {
      var rig = _Rig();
      var a = _light('a', '192.168.1.115');
      var b = _light('b', '192.168.1.118');
      rig.lights.seed([a, b]);
      rig.gateway.failing[a.ip] = const TimeoutFailure('192.168.1.115', 3);
      rig.gateway.failing[b.ip] = const UnreachableFailure(
        '192.168.1.118',
        'x',
      );
      unawaited(rig.network.refresh());
      async.flushMicrotasks();
      rig.listener.start();

      unawaited(rig.pipeline.run(CommandBatch(items: [_item(a), _item(b)])));
      async.flushMicrotasks();
      expect(rig.toasts.toasts.map((t) => t.body), [
        '192.168.1.115 did not answer on port 38899',
        '192.168.1.118 did not answer on port 38899',
      ]);
      async.elapse(_delay * 2);
      expect(
        rig.toasts.toasts,
        hasLength(2),
        reason: 'no loading toast joins them',
      );
      rig.dispose();
    });
  });

  test('off network is one error toast with no retry', () {
    fakeAsync((async) {
      var rig = _Rig(current: '10.0.0');
      var a = _light('a', '192.168.1.115');
      rig.lights.seed([a]);
      unawaited(rig.network.refresh());
      async.flushMicrotasks();
      rig.listener.start();

      unawaited(rig.pipeline.run(CommandBatch(items: [_item(a)])));
      async.flushMicrotasks();
      var toast = rig.toasts.toasts.single;
      expect(toast.tone, WizToastTone.error);
      expect(toast.title, Strings.noRoute);
      expect(toast.body, 'This device is not on 192.168.1.0/24.');
      expect(toast.actionLabel, isNull);
      rig.dispose();
    });
  });
}
