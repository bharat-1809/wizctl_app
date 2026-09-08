import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/data/device/gateway_tuning.dart';
import 'package:wizctl_app/data/device/wiz_device_gateway.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

import '../../support/fake_bulb.dart';

void main() {
  const bulbPort = 39441;
  const replyPort = 39442;
  const deadPort = 39443;

  test(
    'reads state and config from a loopback bulb and sends a pilot',
    () async {
      var bulb = await FakeBulb.start(
        listenPort: bulbPort,
        replyMode: ReplyMode.sourcePort,
      );
      addTearDown(bulb.close);
      var gateway = WizDeviceGateway(
        tuning: const GatewayTuning(port: bulbPort, localPort: replyPort),
      );
      var state = await gateway.readState('127.0.0.1');
      expect(state.isOn, isTrue);
      expect(state.dimming, 70);
      var config = await gateway.readConfig('127.0.0.1');
      expect(config.moduleName, 'ESP01_SHRGB_03');
      await gateway.send('127.0.0.1', ControlSignal.on());
      expect(bulb.requestCount, 3);
    },
  );

  test(
    'a silent address fails with a device exception in bounded time',
    () async {
      var gateway = WizDeviceGateway(
        tuning: const GatewayTuning(
          port: deadPort,
          readTimeout: Duration(milliseconds: 200),
          readRetry: RetryConfig.none(),
          writeTimeout: Duration(milliseconds: 200),
          writeRetry: RetryConfig.none(),
        ),
      );
      var watch = Stopwatch()..start();
      await expectLater(
        gateway.readState('127.0.0.1'),
        throwsA(isA<DeviceException>()),
      );
      await expectLater(
        gateway.send('127.0.0.1', ControlSignal.on()),
        throwsA(isA<DeviceException>()),
      );
      expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
    },
  );

  test('probe streams scan events', () async {
    var bulb = await FakeBulb.start(
      listenPort: bulbPort,
      replyMode: ReplyMode.sourcePort,
    );
    addTearDown(bulb.close);
    var gateway = WizDeviceGateway(
      tuning: const GatewayTuning(
        port: bulbPort,
        localPort: replyPort,
        readTimeout: Duration(seconds: 1),
      ),
    );
    var events = await gateway.probe(['127.0.0.1']).toList();
    expect(events.whereType<ScanFound>(), hasLength(1));
    expect(events.last, isA<ScanDone>());
  });

  test('maps library errors to failures', () {
    expect(
      WizDeviceGateway.mapError(
        WizTimeoutError(
          ip: '1.2.3.4',
          timeout: const Duration(seconds: 1),
          retryCount: 3,
        ),
        '1.2.3.4',
      ),
      const TimeoutFailure('1.2.3.4', 3),
    );
    expect(
      WizDeviceGateway.mapError(WizConnectionError('no route'), '1.2.3.4'),
      isA<UnreachableFailure>(),
    );
    expect(
      WizDeviceGateway.mapError(
        WizMethodNotFoundError(method: 'getModelConfig', ip: '1.2.3.4'),
        '1.2.3.4',
      ),
      const UnsupportedFailure('1.2.3.4', 'getModelConfig'),
    );
    expect(
      WizDeviceGateway.mapError(
        WizArgumentError(argumentName: 'x', invalidValue: 1, message: 'bad'),
        '1.2.3.4',
      ),
      const InvalidArgumentFailure('bad'),
    );
    expect(
      WizDeviceGateway.mapError(StateError('boom'), '1.2.3.4'),
      isA<UnreachableFailure>(),
    );
  });
}
