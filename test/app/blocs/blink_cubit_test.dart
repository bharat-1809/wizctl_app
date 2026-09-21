import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/blocs/blink_cubit.dart';
import 'package:wizctl_app/app/blocs/blink_state.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';

import '../../support/fakes.dart';

/// A gateway whose read throws something the domain never modelled, the way a
/// closed database or a platform channel that has gone away would.
class _BrokenGateway extends FakeGateway {
  @override
  Future<LightState> readState(String ip) async =>
      throw StateError('the socket went away');
}

void main() {
  late FakeGateway gateway;
  late FakeClock clock;

  BlinkCubit build() => BlinkCubit(
    blink: BlinkLight(gateway: gateway, clock: clock),
  );

  setUp(() {
    gateway = FakeGateway();
    clock = FakeClock();
    gateway.states['192.168.1.115'] = const LightState(isOn: false);
  });

  blocTest<BlinkCubit, BlinkState>(
    'a blink is on the set while it runs and gone after',
    build: build,
    act: (cubit) => cubit.blink('192.168.1.115', bulbClass: BulbClass.rgb),
    expect: () => [
      const BlinkState(blinking: {'192.168.1.115'}),
      const BlinkState(blinking: {}),
    ],
    verify: (_) {
      expect(gateway.sends, hasLength(2), reason: 'the write and the restore');
      expect(clock.delays, [const Duration(seconds: 2)]);
    },
  );

  blocTest<BlinkCubit, BlinkState>(
    'a throw the domain never modelled still lets the ip go',
    build: build,
    setUp: () => gateway = _BrokenGateway(),
    act: (cubit) => cubit.blink('192.168.1.115'),
    verify: (cubit) => expect(
      cubit.state.blinking,
      isEmpty,
      reason: 'otherwise the flash key stays amber for the life of the app',
    ),
  );

  blocTest<BlinkCubit, BlinkState>(
    'a second tap while blinking is ignored',
    build: build,
    act: (cubit) async {
      var first = cubit.blink('192.168.1.115');
      await cubit.blink('192.168.1.115');
      await first;
    },
    verify: (_) => expect(gateway.sends, hasLength(2)),
  );

  blocTest<BlinkCubit, BlinkState>(
    'a bulb that does not answer raises the failure and never blinks',
    build: build,
    setUp: () => gateway.failing['192.168.1.115'] = const TimeoutFailure(
      '192.168.1.115',
      2,
    ),
    act: (cubit) async {
      await cubit.blink('192.168.1.115');
      cubit.clearFailure();
    },
    expect: () => [
      const BlinkState(blinking: {'192.168.1.115'}),
      const BlinkState(
        blinking: {},
        failure: BlinkFailure(
          '192.168.1.115',
          TimeoutFailure('192.168.1.115', 2),
        ),
      ),
      const BlinkState(blinking: {}),
    ],
    verify: (_) => expect(gateway.sends, isEmpty),
  );
}
