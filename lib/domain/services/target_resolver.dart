import '../entities/light.dart';
import '../entities/mode_target.dart';
import '../repositories/light_repository.dart';

/// Which lights a target means, in repository order.
class TargetResolver {
  final LightRepository _lights;

  TargetResolver(this._lights);

  Future<List<Light>> resolve(ModeTarget target) async => switch (target) {
    WholeHomeTarget(:var homeId) => _lights.getByHome(homeId),
    RoomTarget(:var roomId) => _lights.getByRoom(roomId),
    LightTarget(:var lightId) => [?await _lights.get(lightId)],
  };
}
