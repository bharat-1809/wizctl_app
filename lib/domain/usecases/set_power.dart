import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import 'target_command.dart';

class SetPower extends TargetCommand {
  const SetPower({
    required super.resolver,
    required super.store,
    required super.pipeline,
  });

  Future<void> call(ModeTarget target, bool on) => dispatch(
    target,
    eligible: (_, _) => true,
    signal: (_, _) => ControlSignal(state: on),
    patch: (s) => s.copyWith(isOn: on),
  );
}
