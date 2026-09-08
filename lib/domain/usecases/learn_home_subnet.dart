import '../repositories/home_repository.dart';

/// A home learns its subnet from the first successful discovery and never
/// overwrites it (spec §5.7.5).
class LearnHomeSubnet {
  final HomeRepository _homes;

  LearnHomeSubnet({required HomeRepository homes})
    : _homes = homes; // ignore: prefer_initializing_formals

  Future<void> call(String homeId, String subnet) async {
    var home = await _homes.get(homeId);
    if (home == null || home.subnet != null) return;
    await _homes.update(home.copyWith(subnet: subnet));
  }
}
