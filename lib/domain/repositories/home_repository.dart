import '../entities/home.dart';

abstract interface class HomeRepository {
  Stream<List<Home>> watchAll();
  Future<List<Home>> getAll();
  Future<Home?> get(String id);
  Future<void> insert(Home home);
  Future<void> update(Home home);
  Future<void> delete(String id);
}
