import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
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

/// A repository whose [get] takes [latency], so a batch can finish while the
/// listener is still reading the light it would name in its loading toast.
class _SlowLights extends FakeLightRepository {
  Duration latency = Duration.zero;

  @override
  Future<Light?> get(String id) async {
    await Future<void>.delayed(latency);
    return super.get(id);
  }
}

/// A whole pipeline over the fakes, so the listener is tested against the
/// reports the real one emits rather than a hand-written sequence.
class _Rig {
  final gateway = FakeGateway();
  final store = LiveStateStore();
  final toasts = ToastController();
  late final FakeLightRepository lights;
  late final NetworkMonitor network;
  late final DeviceCommandPipeline pipeline;
  late final CommandToastListener listener;
  String? homeSubnet = '192.168.1';

  _Rig({String? current = '192.168.1', FakeLightRepository? lights}) {
    this.lights = lights ?? FakeLightRepository();
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
      lights: this.lights,
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

  test('a read that fails still puts the batch\'s loading toast up', () {
    fakeAsync((async) {
      var rig = _Rig();
      var a = _light('a', '192.168.1.115');
      rig.lights.seed([a]);
      rig.gateway.sendLatency = const Duration(seconds: 2);
      unawaited(rig.network.refresh());
      async.flushMicrotasks();
      rig.listener.start();

      // Captured rather than left to print. A plain `test()` leaves
      // `FlutterError.onError` at `dumpErrorToConsole`, so the listener's
      // report would put an error box in the suite's output — and capturing it
      // is the assertion that a failed read is *reported*, not swallowed.
      var reported = <FlutterErrorDetails>[];
      var previousOnError = FlutterError.onError;
      FlutterError.onError = reported.add;
      try {
        // The name is what the read was for; without it the toast falls back
        // to the count, rather than the batch going silent.
        rig.lights.getError = StateError('database closed');
        unawaited(rig.pipeline.run(CommandBatch(items: [_item(a)])));
        async.elapse(_delay * 2);
        var toast = rig.toasts.toasts.single;
        expect(toast.tone, WizToastTone.loading);
        expect(toast.title, Strings.sendingToLights(1));
        expect(toast.body, isNull, reason: 'no address was read either');
        async.elapse(const Duration(seconds: 4));
      } finally {
        FlutterError.onError = previousOnError;
      }

      expect(reported, hasLength(1), reason: 'reported once, and only once');
      expect(reported.single.library, 'wizctl_app');
      expect(
        reported.single.exception,
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'database closed',
        ),
        reason: "the fake's own failure, not one the listener invented",
      );
      rig.dispose();
    });
  });

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

  test('Retry on any error toast of a batch retries the whole batch once', () {
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
      expect(rig.toasts.toasts.map((t) => t.actionLabel), [
        Strings.retry,
        Strings.retry,
      ]);

      // The second toast's Retry stands for the whole batch: both errors go,
      // and the one loading toast that replaces them counts the lights the
      // pipeline is resending.
      rig.gateway.failing.clear();
      rig.toasts.toasts.last.onAction!();
      var loading = rig.toasts.toasts.single;
      expect(loading.tone, WizToastTone.loading);
      expect(loading.title, 'Retrying 2 lights');
      expect(loading.actionLabel, isNull);

      async.flushMicrotasks();
      async.flushMicrotasks();
      expect(rig.toasts.toasts, isEmpty, reason: 'both resends succeeded');
      async.elapse(_delay * 2);
      expect(rig.toasts.toasts, isEmpty, reason: 'nothing was left armed');
      rig.dispose();
    });
  });

  test('a batch retry that fails again is one Still no reply', () {
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
      rig.toasts.toasts.last.onAction!();
      async.flushMicrotasks();
      async.flushMicrotasks();
      var toast = rig.toasts.toasts.single;
      expect(toast.tone, WizToastTone.error);
      expect(toast.title, Strings.stillNoReply);
      expect(toast.body, Strings.checkWallSwitch);
      expect(toast.actionLabel, isNull);
      rig.dispose();
    });
  });

  test('a light that no longer exists arms no toast, but still reports', () {
    fakeAsync((async) {
      var rig = _Rig();
      var a = _light('a', '192.168.1.115');
      rig.lights.seed([a]);
      rig.gateway.sendLatency = const Duration(seconds: 2);
      rig.gateway.failing[a.ip] = const TimeoutFailure('192.168.1.115', 3);
      unawaited(rig.network.refresh());
      async.flushMicrotasks();
      rig.listener.start();

      // Deleted between the send and the listener's read of it: the loading
      // toast has no name and no address left to show.
      unawaited(rig.pipeline.run(CommandBatch(items: [_item(a)])));
      unawaited(rig.lights.delete(a.id));
      async.elapse(_delay * 2);
      expect(
        rig.toasts.toasts,
        isEmpty,
        reason: 'nothing honest to put in a loading toast',
      );

      // The failure still reports: it carries its own name and address.
      async.elapse(const Duration(seconds: 2));
      var toast = rig.toasts.toasts.single;
      expect(toast.tone, WizToastTone.error);
      expect(toast.title, Strings.noResponseAfterTries);
      expect(toast.body, '192.168.1.115 did not answer on port 38899');
      expect(toast.actionLabel, Strings.retry);
      rig.dispose();
    });
  });

  test('a success that beats the pending read never arms a toast', () {
    fakeAsync((async) {
      var slow = _SlowLights()..latency = const Duration(seconds: 1);
      var rig = _Rig(lights: slow);
      var a = _light('a', '192.168.1.115');
      rig.lights.seed([a]);
      unawaited(rig.network.refresh());
      async.flushMicrotasks();
      rig.listener.start();

      // The send finishes while the listener is still reading the address it
      // would put in the toast.
      unawaited(rig.pipeline.run(CommandBatch(items: [_item(a)])));
      async.flushMicrotasks();
      expect(rig.toasts.toasts, isEmpty);
      async.elapse(const Duration(seconds: 1) + _delay * 2);
      expect(
        rig.toasts.toasts,
        isEmpty,
        reason: 'the read came back to a batch that had already succeeded',
      );
      rig.dispose();
    });
  });

  test('a failure that beats the pending read never arms a toast either', () {
    fakeAsync((async) {
      var slow = _SlowLights()..latency = const Duration(seconds: 1);
      var rig = _Rig(lights: slow);
      var a = _light('a', '192.168.1.115');
      rig.lights.seed([a]);
      rig.gateway.failing[a.ip] = const TimeoutFailure('192.168.1.115', 3);
      unawaited(rig.network.refresh());
      async.flushMicrotasks();
      rig.listener.start();

      unawaited(rig.pipeline.run(CommandBatch(items: [_item(a)])));
      async.flushMicrotasks();
      expect(rig.toasts.toasts.single.title, Strings.noResponseAfterTries);
      // The read comes back at 1 s to a batch that already has an error toast,
      // and the delayed loading toast would have surfaced 600 ms after that.
      async.elapse(const Duration(seconds: 1) + _delay);
      expect(
        rig.toasts.toasts.single.title,
        Strings.noResponseAfterTries,
        reason: 'no loading toast joined the error it already reported',
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

  test('no IPv4 address at all says so rather than naming the home', () {
    fakeAsync((async) {
      // No current subnet: off network because the home has one and this
      // device is on nothing, which is the real "no local network".
      var rig = _Rig(current: null);
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
      expect(toast.body, 'This device has no local network.');
      expect(toast.actionLabel, isNull);
      rig.dispose();
    });
  });
}
