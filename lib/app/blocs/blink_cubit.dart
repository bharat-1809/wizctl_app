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
    var failure = state.failure;
    try {
      await _blink(ip, bulbClass: bulbClass);
    } on DeviceException catch (e) {
      failure = BlinkFailure(ip, e.failure);
    } catch (_) {
      // Anything the domain never modelled — a closed database, a platform
      // channel that went away — has to let the ip go too, or the flash key
      // stays amber for the life of the app and the row can never be tried
      // again. Caught rather than rethrown, and deliberately not turned into a
      // `BlinkFailure`: nothing in `lib` renders one, so a stuck key is the
      // only consequence the user would ever have seen.
    }
    // One emission for all three outcomes, and it reads `state.blinking` as it
    // is now rather than as it was: another address may have started blinking
    // while this one was in flight.
    emit(
      BlinkState(blinking: {...state.blinking}..remove(ip), failure: failure),
    );
  }

  void clearFailure() => emit(BlinkState(blinking: state.blinking));
}
