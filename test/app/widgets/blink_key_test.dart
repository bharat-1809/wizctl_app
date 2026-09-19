import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/app/blocs/blink_cubit.dart';
import 'package:wizctl_app/app/widgets/blink_key.dart';
import 'package:wizctl_app/core/copy/strings.dart';
import 'package:wizctl_app/core/widgets/wiz_icon_key.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';

import '../../support/fakes.dart';
import '../../support/wiz_test_app.dart';

void main() {
  testWidgets('tapping blinks and the key is active while it does', (
    tester,
  ) async {
    var gateway = FakeGateway()
      ..states['192.168.1.115'] = const LightState(isOn: true)
      ..sendLatency = const Duration(milliseconds: 100);
    var cubit = BlinkCubit(
      blink: BlinkLight(gateway: gateway, clock: FakeClock()),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      wizTestApp(
        BlocProvider.value(
          value: cubit,
          child: const BlinkKey(ip: '192.168.1.115', bulbClass: BulbClass.rgb),
        ),
      ),
    );
    expect(tester.widget<WizIconKey>(find.byType(WizIconKey)).active, isFalse);
    await tester.tap(find.bySemanticsLabel(Strings.blinkLight));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<WizIconKey>(find.byType(WizIconKey)).active, isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(tester.widget<WizIconKey>(find.byType(WizIconKey)).active, isFalse);
    expect(gateway.sends, hasLength(2));
  });
}
