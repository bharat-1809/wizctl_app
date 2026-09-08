import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

@DataClassName('HomeRow')
class Homes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get subnet => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RoomRow')
class Rooms extends Table {
  TextColumn get id => text()();
  TextColumn get homeId =>
      text().references(Homes, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get glyph => text()();
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LightRow')
class Lights extends Table {
  TextColumn get id => text()();
  TextColumn get homeId =>
      text().references(Homes, #id, onDelete: KeyAction.cascade)();
  // NO ACTION rather than RESTRICT: SQLite fires cascades in an unspecified
  // order, so deleting a home could trip an immediate RESTRICT on
  // homes->rooms before the homes->lights cascade has removed the lights.
  // NO ACTION is deferred to statement end, so the home cascade still
  // succeeds while a direct room delete with lights still present is still
  // refused once the statement finishes.
  TextColumn get roomId =>
      text().references(Rooms, #id, onDelete: KeyAction.noAction)();
  TextColumn get name => text()();
  TextColumn get ip => text()();
  TextColumn get mac => text()();
  TextColumn get moduleName => text().nullable()();
  TextColumn get bulbClass => text().nullable()();
  TextColumn get fixture => text()();
  TextColumn get fwVersion => text().nullable()();
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();
  IntColumn get addedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {homeId, mac},
  ];
}

/// Last-known live state, so the app opens showing real values.
@DataClassName('LightStateRow')
class LightStates extends Table {
  TextColumn get lightId =>
      text().references(Lights, #id, onDelete: KeyAction.cascade)();
  BoolColumn get isOn => boolean()();
  IntColumn get brightness => integer()();
  IntColumn get kelvin => integer()();
  IntColumn get r => integer()();
  IntColumn get g => integer()();
  IntColumn get b => integer()();
  IntColumn get sceneId => integer()();
  IntColumn get speed => integer()();
  TextColumn get active => text()();
  IntColumn get rssi => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {lightId};
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Homes, Rooms, Lights, LightStates, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.inMemory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // SQLite ignores foreign keys unless asked; cascade and restrict
      // depend on this.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
