import '../repositories/home_repository.dart';
import 'usecase_exceptions.dart';

/// Renames a home, if it still exists.
class RenameHome {
  final HomeRepository _homes;

  RenameHome({required HomeRepository homes})
    : _homes = homes; // ignore: prefer_initializing_formals

  Future<void> call(String id, String name) async {
    var trimmed = name.trim();
    if (trimmed.isEmpty) throw const EmptyNameException();
    var home = await _homes.get(id);
    if (home != null) await _homes.update(home.copyWith(name: trimmed));
  }
}
