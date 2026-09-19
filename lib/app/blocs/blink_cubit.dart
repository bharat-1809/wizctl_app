import 'package:bloc/bloc.dart';
import 'package:wizctl/wizctl.dart';

import '../../domain/entities/entities.dart';
import '../../domain/usecases/usecases.dart';
import 'blink_state.dart';

/// Which addresses are blinking right now (spec §5.10, §8). A tap while an
/// address is blinking is ignored; the key and the row's well read the set.
class BlinkCubit extends Cubit<BlinkState> {
  final BlinkLight _blink;

  BlinkCubit({required BlinkLight blink})
    : _blink = blink, // ignore: prefer_initializing_formals
      super(const BlinkState(blinking: {}));

  Future<void> blink(String ip, {BulbClass? bulbClass}) async {
    if (state.isBlinking(ip)) return;
    emit(BlinkState(blinking: {...state.blinking, ip}, failure: state.failure));
    try {
      await _blink(ip, bulbClass: bulbClass);
      emit(
        BlinkState(
          blinking: {...state.blinking}..remove(ip),
          failure: state.failure,
        ),
      );
    } on DeviceException catch (e) {
      emit(
        BlinkState(
          blinking: {...state.blinking}..remove(ip),
          failure: BlinkFailure(ip, e.failure),
        ),
      );
    }
  }

  void clearFailure() => emit(BlinkState(blinking: state.blinking));
}
