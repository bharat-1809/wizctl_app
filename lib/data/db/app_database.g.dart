// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HomesTable extends Homes with TableInfo<$HomesTable, HomeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HomesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subnetMeta = const VerificationMeta('subnet');
  @override
  late final GeneratedColumn<String> subnet = GeneratedColumn<String>(
    'subnet',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortIndexMeta = const VerificationMeta(
    'sortIndex',
  );
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
    'sort_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    subnet,
    createdAt,
    sortIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'homes';
  @override
  VerificationContext validateIntegrity(
    Insertable<HomeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('subnet')) {
      context.handle(
        _subnetMeta,
        subnet.isAcceptableOrUnknown(data['subnet']!, _subnetMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sort_index')) {
      context.handle(
        _sortIndexMeta,
        sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HomeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HomeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      subnet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subnet'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      sortIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_index'],
      )!,
    );
  }

  @override
  $HomesTable createAlias(String alias) {
    return $HomesTable(attachedDatabase, alias);
  }
}

class HomeRow extends DataClass implements Insertable<HomeRow> {
  final String id;
  final String name;
  final String? subnet;
  final int createdAt;
  final int sortIndex;
  const HomeRow({
    required this.id,
    required this.name,
    this.subnet,
    required this.createdAt,
    required this.sortIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || subnet != null) {
      map['subnet'] = Variable<String>(subnet);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['sort_index'] = Variable<int>(sortIndex);
    return map;
  }

  HomesCompanion toCompanion(bool nullToAbsent) {
    return HomesCompanion(
      id: Value(id),
      name: Value(name),
      subnet: subnet == null && nullToAbsent
          ? const Value.absent()
          : Value(subnet),
      createdAt: Value(createdAt),
      sortIndex: Value(sortIndex),
    );
  }

  factory HomeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HomeRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      subnet: serializer.fromJson<String?>(json['subnet']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'subnet': serializer.toJson<String?>(subnet),
      'createdAt': serializer.toJson<int>(createdAt),
      'sortIndex': serializer.toJson<int>(sortIndex),
    };
  }

  HomeRow copyWith({
    String? id,
    String? name,
    Value<String?> subnet = const Value.absent(),
    int? createdAt,
    int? sortIndex,
  }) => HomeRow(
    id: id ?? this.id,
    name: name ?? this.name,
    subnet: subnet.present ? subnet.value : this.subnet,
    createdAt: createdAt ?? this.createdAt,
    sortIndex: sortIndex ?? this.sortIndex,
  );
  HomeRow copyWithCompanion(HomesCompanion data) {
    return HomeRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      subnet: data.subnet.present ? data.subnet.value : this.subnet,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HomeRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('subnet: $subnet, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortIndex: $sortIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, subnet, createdAt, sortIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HomeRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.subnet == this.subnet &&
          other.createdAt == this.createdAt &&
          other.sortIndex == this.sortIndex);
}

class HomesCompanion extends UpdateCompanion<HomeRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> subnet;
  final Value<int> createdAt;
  final Value<int> sortIndex;
  final Value<int> rowid;
  const HomesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.subnet = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HomesCompanion.insert({
    required String id,
    required String name,
    this.subnet = const Value.absent(),
    required int createdAt,
    this.sortIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<HomeRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? subnet,
    Expression<int>? createdAt,
    Expression<int>? sortIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (subnet != null) 'subnet': subnet,
      if (createdAt != null) 'created_at': createdAt,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HomesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? subnet,
    Value<int>? createdAt,
    Value<int>? sortIndex,
    Value<int>? rowid,
  }) {
    return HomesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      subnet: subnet ?? this.subnet,
      createdAt: createdAt ?? this.createdAt,
      sortIndex: sortIndex ?? this.sortIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (subnet.present) {
      map['subnet'] = Variable<String>(subnet.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HomesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('subnet: $subnet, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoomsTable extends Rooms with TableInfo<$RoomsTable, RoomRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeIdMeta = const VerificationMeta('homeId');
  @override
  late final GeneratedColumn<String> homeId = GeneratedColumn<String>(
    'home_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES homes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _glyphMeta = const VerificationMeta('glyph');
  @override
  late final GeneratedColumn<String> glyph = GeneratedColumn<String>(
    'glyph',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortIndexMeta = const VerificationMeta(
    'sortIndex',
  );
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
    'sort_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, homeId, name, glyph, sortIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rooms';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoomRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('home_id')) {
      context.handle(
        _homeIdMeta,
        homeId.isAcceptableOrUnknown(data['home_id']!, _homeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_homeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('glyph')) {
      context.handle(
        _glyphMeta,
        glyph.isAcceptableOrUnknown(data['glyph']!, _glyphMeta),
      );
    } else if (isInserting) {
      context.missing(_glyphMeta);
    }
    if (data.containsKey('sort_index')) {
      context.handle(
        _sortIndexMeta,
        sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoomRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoomRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      homeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      glyph: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}glyph'],
      )!,
      sortIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_index'],
      )!,
    );
  }

  @override
  $RoomsTable createAlias(String alias) {
    return $RoomsTable(attachedDatabase, alias);
  }
}

class RoomRow extends DataClass implements Insertable<RoomRow> {
  final String id;
  final String homeId;
  final String name;
  final String glyph;
  final int sortIndex;
  const RoomRow({
    required this.id,
    required this.homeId,
    required this.name,
    required this.glyph,
    required this.sortIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['home_id'] = Variable<String>(homeId);
    map['name'] = Variable<String>(name);
    map['glyph'] = Variable<String>(glyph);
    map['sort_index'] = Variable<int>(sortIndex);
    return map;
  }

  RoomsCompanion toCompanion(bool nullToAbsent) {
    return RoomsCompanion(
      id: Value(id),
      homeId: Value(homeId),
      name: Value(name),
      glyph: Value(glyph),
      sortIndex: Value(sortIndex),
    );
  }

  factory RoomRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoomRow(
      id: serializer.fromJson<String>(json['id']),
      homeId: serializer.fromJson<String>(json['homeId']),
      name: serializer.fromJson<String>(json['name']),
      glyph: serializer.fromJson<String>(json['glyph']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'homeId': serializer.toJson<String>(homeId),
      'name': serializer.toJson<String>(name),
      'glyph': serializer.toJson<String>(glyph),
      'sortIndex': serializer.toJson<int>(sortIndex),
    };
  }

  RoomRow copyWith({
    String? id,
    String? homeId,
    String? name,
    String? glyph,
    int? sortIndex,
  }) => RoomRow(
    id: id ?? this.id,
    homeId: homeId ?? this.homeId,
    name: name ?? this.name,
    glyph: glyph ?? this.glyph,
    sortIndex: sortIndex ?? this.sortIndex,
  );
  RoomRow copyWithCompanion(RoomsCompanion data) {
    return RoomRow(
      id: data.id.present ? data.id.value : this.id,
      homeId: data.homeId.present ? data.homeId.value : this.homeId,
      name: data.name.present ? data.name.value : this.name,
      glyph: data.glyph.present ? data.glyph.value : this.glyph,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoomRow(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('name: $name, ')
          ..write('glyph: $glyph, ')
          ..write('sortIndex: $sortIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, homeId, name, glyph, sortIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoomRow &&
          other.id == this.id &&
          other.homeId == this.homeId &&
          other.name == this.name &&
          other.glyph == this.glyph &&
          other.sortIndex == this.sortIndex);
}

class RoomsCompanion extends UpdateCompanion<RoomRow> {
  final Value<String> id;
  final Value<String> homeId;
  final Value<String> name;
  final Value<String> glyph;
  final Value<int> sortIndex;
  final Value<int> rowid;
  const RoomsCompanion({
    this.id = const Value.absent(),
    this.homeId = const Value.absent(),
    this.name = const Value.absent(),
    this.glyph = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoomsCompanion.insert({
    required String id,
    required String homeId,
    required String name,
    required String glyph,
    this.sortIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       homeId = Value(homeId),
       name = Value(name),
       glyph = Value(glyph);
  static Insertable<RoomRow> custom({
    Expression<String>? id,
    Expression<String>? homeId,
    Expression<String>? name,
    Expression<String>? glyph,
    Expression<int>? sortIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (homeId != null) 'home_id': homeId,
      if (name != null) 'name': name,
      if (glyph != null) 'glyph': glyph,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoomsCompanion copyWith({
    Value<String>? id,
    Value<String>? homeId,
    Value<String>? name,
    Value<String>? glyph,
    Value<int>? sortIndex,
    Value<int>? rowid,
  }) {
    return RoomsCompanion(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      glyph: glyph ?? this.glyph,
      sortIndex: sortIndex ?? this.sortIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (homeId.present) {
      map['home_id'] = Variable<String>(homeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (glyph.present) {
      map['glyph'] = Variable<String>(glyph.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomsCompanion(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('name: $name, ')
          ..write('glyph: $glyph, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LightsTable extends Lights with TableInfo<$LightsTable, LightRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeIdMeta = const VerificationMeta('homeId');
  @override
  late final GeneratedColumn<String> homeId = GeneratedColumn<String>(
    'home_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES homes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rooms (id) ON DELETE NO ACTION',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ipMeta = const VerificationMeta('ip');
  @override
  late final GeneratedColumn<String> ip = GeneratedColumn<String>(
    'ip',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _macMeta = const VerificationMeta('mac');
  @override
  late final GeneratedColumn<String> mac = GeneratedColumn<String>(
    'mac',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moduleNameMeta = const VerificationMeta(
    'moduleName',
  );
  @override
  late final GeneratedColumn<String> moduleName = GeneratedColumn<String>(
    'module_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bulbClassMeta = const VerificationMeta(
    'bulbClass',
  );
  @override
  late final GeneratedColumn<String> bulbClass = GeneratedColumn<String>(
    'bulb_class',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixtureMeta = const VerificationMeta(
    'fixture',
  );
  @override
  late final GeneratedColumn<String> fixture = GeneratedColumn<String>(
    'fixture',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fwVersionMeta = const VerificationMeta(
    'fwVersion',
  );
  @override
  late final GeneratedColumn<String> fwVersion = GeneratedColumn<String>(
    'fw_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortIndexMeta = const VerificationMeta(
    'sortIndex',
  );
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
    'sort_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    homeId,
    roomId,
    name,
    ip,
    mac,
    moduleName,
    bulbClass,
    fixture,
    fwVersion,
    sortIndex,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lights';
  @override
  VerificationContext validateIntegrity(
    Insertable<LightRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('home_id')) {
      context.handle(
        _homeIdMeta,
        homeId.isAcceptableOrUnknown(data['home_id']!, _homeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_homeIdMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('ip')) {
      context.handle(_ipMeta, ip.isAcceptableOrUnknown(data['ip']!, _ipMeta));
    } else if (isInserting) {
      context.missing(_ipMeta);
    }
    if (data.containsKey('mac')) {
      context.handle(
        _macMeta,
        mac.isAcceptableOrUnknown(data['mac']!, _macMeta),
      );
    } else if (isInserting) {
      context.missing(_macMeta);
    }
    if (data.containsKey('module_name')) {
      context.handle(
        _moduleNameMeta,
        moduleName.isAcceptableOrUnknown(data['module_name']!, _moduleNameMeta),
      );
    }
    if (data.containsKey('bulb_class')) {
      context.handle(
        _bulbClassMeta,
        bulbClass.isAcceptableOrUnknown(data['bulb_class']!, _bulbClassMeta),
      );
    }
    if (data.containsKey('fixture')) {
      context.handle(
        _fixtureMeta,
        fixture.isAcceptableOrUnknown(data['fixture']!, _fixtureMeta),
      );
    } else if (isInserting) {
      context.missing(_fixtureMeta);
    }
    if (data.containsKey('fw_version')) {
      context.handle(
        _fwVersionMeta,
        fwVersion.isAcceptableOrUnknown(data['fw_version']!, _fwVersionMeta),
      );
    }
    if (data.containsKey('sort_index')) {
      context.handle(
        _sortIndexMeta,
        sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {homeId, mac},
  ];
  @override
  LightRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LightRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      homeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      ip: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ip'],
      )!,
      mac: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mac'],
      )!,
      moduleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module_name'],
      ),
      bulbClass: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bulb_class'],
      ),
      fixture: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixture'],
      )!,
      fwVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fw_version'],
      ),
      sortIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_index'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $LightsTable createAlias(String alias) {
    return $LightsTable(attachedDatabase, alias);
  }
}

class LightRow extends DataClass implements Insertable<LightRow> {
  final String id;
  final String homeId;
  final String roomId;
  final String name;
  final String ip;
  final String mac;
  final String? moduleName;
  final String? bulbClass;
  final String fixture;
  final String? fwVersion;
  final int sortIndex;
  final int addedAt;
  const LightRow({
    required this.id,
    required this.homeId,
    required this.roomId,
    required this.name,
    required this.ip,
    required this.mac,
    this.moduleName,
    this.bulbClass,
    required this.fixture,
    this.fwVersion,
    required this.sortIndex,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['home_id'] = Variable<String>(homeId);
    map['room_id'] = Variable<String>(roomId);
    map['name'] = Variable<String>(name);
    map['ip'] = Variable<String>(ip);
    map['mac'] = Variable<String>(mac);
    if (!nullToAbsent || moduleName != null) {
      map['module_name'] = Variable<String>(moduleName);
    }
    if (!nullToAbsent || bulbClass != null) {
      map['bulb_class'] = Variable<String>(bulbClass);
    }
    map['fixture'] = Variable<String>(fixture);
    if (!nullToAbsent || fwVersion != null) {
      map['fw_version'] = Variable<String>(fwVersion);
    }
    map['sort_index'] = Variable<int>(sortIndex);
    map['added_at'] = Variable<int>(addedAt);
    return map;
  }

  LightsCompanion toCompanion(bool nullToAbsent) {
    return LightsCompanion(
      id: Value(id),
      homeId: Value(homeId),
      roomId: Value(roomId),
      name: Value(name),
      ip: Value(ip),
      mac: Value(mac),
      moduleName: moduleName == null && nullToAbsent
          ? const Value.absent()
          : Value(moduleName),
      bulbClass: bulbClass == null && nullToAbsent
          ? const Value.absent()
          : Value(bulbClass),
      fixture: Value(fixture),
      fwVersion: fwVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(fwVersion),
      sortIndex: Value(sortIndex),
      addedAt: Value(addedAt),
    );
  }

  factory LightRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LightRow(
      id: serializer.fromJson<String>(json['id']),
      homeId: serializer.fromJson<String>(json['homeId']),
      roomId: serializer.fromJson<String>(json['roomId']),
      name: serializer.fromJson<String>(json['name']),
      ip: serializer.fromJson<String>(json['ip']),
      mac: serializer.fromJson<String>(json['mac']),
      moduleName: serializer.fromJson<String?>(json['moduleName']),
      bulbClass: serializer.fromJson<String?>(json['bulbClass']),
      fixture: serializer.fromJson<String>(json['fixture']),
      fwVersion: serializer.fromJson<String?>(json['fwVersion']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'homeId': serializer.toJson<String>(homeId),
      'roomId': serializer.toJson<String>(roomId),
      'name': serializer.toJson<String>(name),
      'ip': serializer.toJson<String>(ip),
      'mac': serializer.toJson<String>(mac),
      'moduleName': serializer.toJson<String?>(moduleName),
      'bulbClass': serializer.toJson<String?>(bulbClass),
      'fixture': serializer.toJson<String>(fixture),
      'fwVersion': serializer.toJson<String?>(fwVersion),
      'sortIndex': serializer.toJson<int>(sortIndex),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  LightRow copyWith({
    String? id,
    String? homeId,
    String? roomId,
    String? name,
    String? ip,
    String? mac,
    Value<String?> moduleName = const Value.absent(),
    Value<String?> bulbClass = const Value.absent(),
    String? fixture,
    Value<String?> fwVersion = const Value.absent(),
    int? sortIndex,
    int? addedAt,
  }) => LightRow(
    id: id ?? this.id,
    homeId: homeId ?? this.homeId,
    roomId: roomId ?? this.roomId,
    name: name ?? this.name,
    ip: ip ?? this.ip,
    mac: mac ?? this.mac,
    moduleName: moduleName.present ? moduleName.value : this.moduleName,
    bulbClass: bulbClass.present ? bulbClass.value : this.bulbClass,
    fixture: fixture ?? this.fixture,
    fwVersion: fwVersion.present ? fwVersion.value : this.fwVersion,
    sortIndex: sortIndex ?? this.sortIndex,
    addedAt: addedAt ?? this.addedAt,
  );
  LightRow copyWithCompanion(LightsCompanion data) {
    return LightRow(
      id: data.id.present ? data.id.value : this.id,
      homeId: data.homeId.present ? data.homeId.value : this.homeId,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      name: data.name.present ? data.name.value : this.name,
      ip: data.ip.present ? data.ip.value : this.ip,
      mac: data.mac.present ? data.mac.value : this.mac,
      moduleName: data.moduleName.present
          ? data.moduleName.value
          : this.moduleName,
      bulbClass: data.bulbClass.present ? data.bulbClass.value : this.bulbClass,
      fixture: data.fixture.present ? data.fixture.value : this.fixture,
      fwVersion: data.fwVersion.present ? data.fwVersion.value : this.fwVersion,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LightRow(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('roomId: $roomId, ')
          ..write('name: $name, ')
          ..write('ip: $ip, ')
          ..write('mac: $mac, ')
          ..write('moduleName: $moduleName, ')
          ..write('bulbClass: $bulbClass, ')
          ..write('fixture: $fixture, ')
          ..write('fwVersion: $fwVersion, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    homeId,
    roomId,
    name,
    ip,
    mac,
    moduleName,
    bulbClass,
    fixture,
    fwVersion,
    sortIndex,
    addedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LightRow &&
          other.id == this.id &&
          other.homeId == this.homeId &&
          other.roomId == this.roomId &&
          other.name == this.name &&
          other.ip == this.ip &&
          other.mac == this.mac &&
          other.moduleName == this.moduleName &&
          other.bulbClass == this.bulbClass &&
          other.fixture == this.fixture &&
          other.fwVersion == this.fwVersion &&
          other.sortIndex == this.sortIndex &&
          other.addedAt == this.addedAt);
}

class LightsCompanion extends UpdateCompanion<LightRow> {
  final Value<String> id;
  final Value<String> homeId;
  final Value<String> roomId;
  final Value<String> name;
  final Value<String> ip;
  final Value<String> mac;
  final Value<String?> moduleName;
  final Value<String?> bulbClass;
  final Value<String> fixture;
  final Value<String?> fwVersion;
  final Value<int> sortIndex;
  final Value<int> addedAt;
  final Value<int> rowid;
  const LightsCompanion({
    this.id = const Value.absent(),
    this.homeId = const Value.absent(),
    this.roomId = const Value.absent(),
    this.name = const Value.absent(),
    this.ip = const Value.absent(),
    this.mac = const Value.absent(),
    this.moduleName = const Value.absent(),
    this.bulbClass = const Value.absent(),
    this.fixture = const Value.absent(),
    this.fwVersion = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LightsCompanion.insert({
    required String id,
    required String homeId,
    required String roomId,
    required String name,
    required String ip,
    required String mac,
    this.moduleName = const Value.absent(),
    this.bulbClass = const Value.absent(),
    required String fixture,
    this.fwVersion = const Value.absent(),
    this.sortIndex = const Value.absent(),
    required int addedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       homeId = Value(homeId),
       roomId = Value(roomId),
       name = Value(name),
       ip = Value(ip),
       mac = Value(mac),
       fixture = Value(fixture),
       addedAt = Value(addedAt);
  static Insertable<LightRow> custom({
    Expression<String>? id,
    Expression<String>? homeId,
    Expression<String>? roomId,
    Expression<String>? name,
    Expression<String>? ip,
    Expression<String>? mac,
    Expression<String>? moduleName,
    Expression<String>? bulbClass,
    Expression<String>? fixture,
    Expression<String>? fwVersion,
    Expression<int>? sortIndex,
    Expression<int>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (homeId != null) 'home_id': homeId,
      if (roomId != null) 'room_id': roomId,
      if (name != null) 'name': name,
      if (ip != null) 'ip': ip,
      if (mac != null) 'mac': mac,
      if (moduleName != null) 'module_name': moduleName,
      if (bulbClass != null) 'bulb_class': bulbClass,
      if (fixture != null) 'fixture': fixture,
      if (fwVersion != null) 'fw_version': fwVersion,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LightsCompanion copyWith({
    Value<String>? id,
    Value<String>? homeId,
    Value<String>? roomId,
    Value<String>? name,
    Value<String>? ip,
    Value<String>? mac,
    Value<String?>? moduleName,
    Value<String?>? bulbClass,
    Value<String>? fixture,
    Value<String?>? fwVersion,
    Value<int>? sortIndex,
    Value<int>? addedAt,
    Value<int>? rowid,
  }) {
    return LightsCompanion(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      mac: mac ?? this.mac,
      moduleName: moduleName ?? this.moduleName,
      bulbClass: bulbClass ?? this.bulbClass,
      fixture: fixture ?? this.fixture,
      fwVersion: fwVersion ?? this.fwVersion,
      sortIndex: sortIndex ?? this.sortIndex,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (homeId.present) {
      map['home_id'] = Variable<String>(homeId.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ip.present) {
      map['ip'] = Variable<String>(ip.value);
    }
    if (mac.present) {
      map['mac'] = Variable<String>(mac.value);
    }
    if (moduleName.present) {
      map['module_name'] = Variable<String>(moduleName.value);
    }
    if (bulbClass.present) {
      map['bulb_class'] = Variable<String>(bulbClass.value);
    }
    if (fixture.present) {
      map['fixture'] = Variable<String>(fixture.value);
    }
    if (fwVersion.present) {
      map['fw_version'] = Variable<String>(fwVersion.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LightsCompanion(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('roomId: $roomId, ')
          ..write('name: $name, ')
          ..write('ip: $ip, ')
          ..write('mac: $mac, ')
          ..write('moduleName: $moduleName, ')
          ..write('bulbClass: $bulbClass, ')
          ..write('fixture: $fixture, ')
          ..write('fwVersion: $fwVersion, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LightStatesTable extends LightStates
    with TableInfo<$LightStatesTable, LightStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LightStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lightIdMeta = const VerificationMeta(
    'lightId',
  );
  @override
  late final GeneratedColumn<String> lightId = GeneratedColumn<String>(
    'light_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lights (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _isOnMeta = const VerificationMeta('isOn');
  @override
  late final GeneratedColumn<bool> isOn = GeneratedColumn<bool>(
    'is_on',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_on" IN (0, 1))',
    ),
  );
  static const VerificationMeta _brightnessMeta = const VerificationMeta(
    'brightness',
  );
  @override
  late final GeneratedColumn<int> brightness = GeneratedColumn<int>(
    'brightness',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kelvinMeta = const VerificationMeta('kelvin');
  @override
  late final GeneratedColumn<int> kelvin = GeneratedColumn<int>(
    'kelvin',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rMeta = const VerificationMeta('r');
  @override
  late final GeneratedColumn<int> r = GeneratedColumn<int>(
    'r',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gMeta = const VerificationMeta('g');
  @override
  late final GeneratedColumn<int> g = GeneratedColumn<int>(
    'g',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bMeta = const VerificationMeta('b');
  @override
  late final GeneratedColumn<int> b = GeneratedColumn<int>(
    'b',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sceneIdMeta = const VerificationMeta(
    'sceneId',
  );
  @override
  late final GeneratedColumn<int> sceneId = GeneratedColumn<int>(
    'scene_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<int> speed = GeneratedColumn<int>(
    'speed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<String> active = GeneratedColumn<String>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rssiMeta = const VerificationMeta('rssi');
  @override
  late final GeneratedColumn<int> rssi = GeneratedColumn<int>(
    'rssi',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    lightId,
    isOn,
    brightness,
    kelvin,
    r,
    g,
    b,
    sceneId,
    speed,
    active,
    rssi,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'light_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<LightStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('light_id')) {
      context.handle(
        _lightIdMeta,
        lightId.isAcceptableOrUnknown(data['light_id']!, _lightIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lightIdMeta);
    }
    if (data.containsKey('is_on')) {
      context.handle(
        _isOnMeta,
        isOn.isAcceptableOrUnknown(data['is_on']!, _isOnMeta),
      );
    } else if (isInserting) {
      context.missing(_isOnMeta);
    }
    if (data.containsKey('brightness')) {
      context.handle(
        _brightnessMeta,
        brightness.isAcceptableOrUnknown(data['brightness']!, _brightnessMeta),
      );
    } else if (isInserting) {
      context.missing(_brightnessMeta);
    }
    if (data.containsKey('kelvin')) {
      context.handle(
        _kelvinMeta,
        kelvin.isAcceptableOrUnknown(data['kelvin']!, _kelvinMeta),
      );
    } else if (isInserting) {
      context.missing(_kelvinMeta);
    }
    if (data.containsKey('r')) {
      context.handle(_rMeta, r.isAcceptableOrUnknown(data['r']!, _rMeta));
    } else if (isInserting) {
      context.missing(_rMeta);
    }
    if (data.containsKey('g')) {
      context.handle(_gMeta, g.isAcceptableOrUnknown(data['g']!, _gMeta));
    } else if (isInserting) {
      context.missing(_gMeta);
    }
    if (data.containsKey('b')) {
      context.handle(_bMeta, b.isAcceptableOrUnknown(data['b']!, _bMeta));
    } else if (isInserting) {
      context.missing(_bMeta);
    }
    if (data.containsKey('scene_id')) {
      context.handle(
        _sceneIdMeta,
        sceneId.isAcceptableOrUnknown(data['scene_id']!, _sceneIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sceneIdMeta);
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    } else if (isInserting) {
      context.missing(_speedMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('rssi')) {
      context.handle(
        _rssiMeta,
        rssi.isAcceptableOrUnknown(data['rssi']!, _rssiMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lightId};
  @override
  LightStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LightStateRow(
      lightId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}light_id'],
      )!,
      isOn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_on'],
      )!,
      brightness: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}brightness'],
      )!,
      kelvin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kelvin'],
      )!,
      r: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}r'],
      )!,
      g: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}g'],
      )!,
      b: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}b'],
      )!,
      sceneId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scene_id'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}speed'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active'],
      )!,
      rssi: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rssi'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LightStatesTable createAlias(String alias) {
    return $LightStatesTable(attachedDatabase, alias);
  }
}

class LightStateRow extends DataClass implements Insertable<LightStateRow> {
  final String lightId;
  final bool isOn;
  final int brightness;
  final int kelvin;
  final int r;
  final int g;
  final int b;
  final int sceneId;
  final int speed;
  final String active;
  final int? rssi;
  final int? updatedAt;
  const LightStateRow({
    required this.lightId,
    required this.isOn,
    required this.brightness,
    required this.kelvin,
    required this.r,
    required this.g,
    required this.b,
    required this.sceneId,
    required this.speed,
    required this.active,
    this.rssi,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['light_id'] = Variable<String>(lightId);
    map['is_on'] = Variable<bool>(isOn);
    map['brightness'] = Variable<int>(brightness);
    map['kelvin'] = Variable<int>(kelvin);
    map['r'] = Variable<int>(r);
    map['g'] = Variable<int>(g);
    map['b'] = Variable<int>(b);
    map['scene_id'] = Variable<int>(sceneId);
    map['speed'] = Variable<int>(speed);
    map['active'] = Variable<String>(active);
    if (!nullToAbsent || rssi != null) {
      map['rssi'] = Variable<int>(rssi);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    return map;
  }

  LightStatesCompanion toCompanion(bool nullToAbsent) {
    return LightStatesCompanion(
      lightId: Value(lightId),
      isOn: Value(isOn),
      brightness: Value(brightness),
      kelvin: Value(kelvin),
      r: Value(r),
      g: Value(g),
      b: Value(b),
      sceneId: Value(sceneId),
      speed: Value(speed),
      active: Value(active),
      rssi: rssi == null && nullToAbsent ? const Value.absent() : Value(rssi),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LightStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LightStateRow(
      lightId: serializer.fromJson<String>(json['lightId']),
      isOn: serializer.fromJson<bool>(json['isOn']),
      brightness: serializer.fromJson<int>(json['brightness']),
      kelvin: serializer.fromJson<int>(json['kelvin']),
      r: serializer.fromJson<int>(json['r']),
      g: serializer.fromJson<int>(json['g']),
      b: serializer.fromJson<int>(json['b']),
      sceneId: serializer.fromJson<int>(json['sceneId']),
      speed: serializer.fromJson<int>(json['speed']),
      active: serializer.fromJson<String>(json['active']),
      rssi: serializer.fromJson<int?>(json['rssi']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lightId': serializer.toJson<String>(lightId),
      'isOn': serializer.toJson<bool>(isOn),
      'brightness': serializer.toJson<int>(brightness),
      'kelvin': serializer.toJson<int>(kelvin),
      'r': serializer.toJson<int>(r),
      'g': serializer.toJson<int>(g),
      'b': serializer.toJson<int>(b),
      'sceneId': serializer.toJson<int>(sceneId),
      'speed': serializer.toJson<int>(speed),
      'active': serializer.toJson<String>(active),
      'rssi': serializer.toJson<int?>(rssi),
      'updatedAt': serializer.toJson<int?>(updatedAt),
    };
  }

  LightStateRow copyWith({
    String? lightId,
    bool? isOn,
    int? brightness,
    int? kelvin,
    int? r,
    int? g,
    int? b,
    int? sceneId,
    int? speed,
    String? active,
    Value<int?> rssi = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
  }) => LightStateRow(
    lightId: lightId ?? this.lightId,
    isOn: isOn ?? this.isOn,
    brightness: brightness ?? this.brightness,
    kelvin: kelvin ?? this.kelvin,
    r: r ?? this.r,
    g: g ?? this.g,
    b: b ?? this.b,
    sceneId: sceneId ?? this.sceneId,
    speed: speed ?? this.speed,
    active: active ?? this.active,
    rssi: rssi.present ? rssi.value : this.rssi,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LightStateRow copyWithCompanion(LightStatesCompanion data) {
    return LightStateRow(
      lightId: data.lightId.present ? data.lightId.value : this.lightId,
      isOn: data.isOn.present ? data.isOn.value : this.isOn,
      brightness: data.brightness.present
          ? data.brightness.value
          : this.brightness,
      kelvin: data.kelvin.present ? data.kelvin.value : this.kelvin,
      r: data.r.present ? data.r.value : this.r,
      g: data.g.present ? data.g.value : this.g,
      b: data.b.present ? data.b.value : this.b,
      sceneId: data.sceneId.present ? data.sceneId.value : this.sceneId,
      speed: data.speed.present ? data.speed.value : this.speed,
      active: data.active.present ? data.active.value : this.active,
      rssi: data.rssi.present ? data.rssi.value : this.rssi,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LightStateRow(')
          ..write('lightId: $lightId, ')
          ..write('isOn: $isOn, ')
          ..write('brightness: $brightness, ')
          ..write('kelvin: $kelvin, ')
          ..write('r: $r, ')
          ..write('g: $g, ')
          ..write('b: $b, ')
          ..write('sceneId: $sceneId, ')
          ..write('speed: $speed, ')
          ..write('active: $active, ')
          ..write('rssi: $rssi, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    lightId,
    isOn,
    brightness,
    kelvin,
    r,
    g,
    b,
    sceneId,
    speed,
    active,
    rssi,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LightStateRow &&
          other.lightId == this.lightId &&
          other.isOn == this.isOn &&
          other.brightness == this.brightness &&
          other.kelvin == this.kelvin &&
          other.r == this.r &&
          other.g == this.g &&
          other.b == this.b &&
          other.sceneId == this.sceneId &&
          other.speed == this.speed &&
          other.active == this.active &&
          other.rssi == this.rssi &&
          other.updatedAt == this.updatedAt);
}

class LightStatesCompanion extends UpdateCompanion<LightStateRow> {
  final Value<String> lightId;
  final Value<bool> isOn;
  final Value<int> brightness;
  final Value<int> kelvin;
  final Value<int> r;
  final Value<int> g;
  final Value<int> b;
  final Value<int> sceneId;
  final Value<int> speed;
  final Value<String> active;
  final Value<int?> rssi;
  final Value<int?> updatedAt;
  final Value<int> rowid;
  const LightStatesCompanion({
    this.lightId = const Value.absent(),
    this.isOn = const Value.absent(),
    this.brightness = const Value.absent(),
    this.kelvin = const Value.absent(),
    this.r = const Value.absent(),
    this.g = const Value.absent(),
    this.b = const Value.absent(),
    this.sceneId = const Value.absent(),
    this.speed = const Value.absent(),
    this.active = const Value.absent(),
    this.rssi = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LightStatesCompanion.insert({
    required String lightId,
    required bool isOn,
    required int brightness,
    required int kelvin,
    required int r,
    required int g,
    required int b,
    required int sceneId,
    required int speed,
    required String active,
    this.rssi = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : lightId = Value(lightId),
       isOn = Value(isOn),
       brightness = Value(brightness),
       kelvin = Value(kelvin),
       r = Value(r),
       g = Value(g),
       b = Value(b),
       sceneId = Value(sceneId),
       speed = Value(speed),
       active = Value(active);
  static Insertable<LightStateRow> custom({
    Expression<String>? lightId,
    Expression<bool>? isOn,
    Expression<int>? brightness,
    Expression<int>? kelvin,
    Expression<int>? r,
    Expression<int>? g,
    Expression<int>? b,
    Expression<int>? sceneId,
    Expression<int>? speed,
    Expression<String>? active,
    Expression<int>? rssi,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lightId != null) 'light_id': lightId,
      if (isOn != null) 'is_on': isOn,
      if (brightness != null) 'brightness': brightness,
      if (kelvin != null) 'kelvin': kelvin,
      if (r != null) 'r': r,
      if (g != null) 'g': g,
      if (b != null) 'b': b,
      if (sceneId != null) 'scene_id': sceneId,
      if (speed != null) 'speed': speed,
      if (active != null) 'active': active,
      if (rssi != null) 'rssi': rssi,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LightStatesCompanion copyWith({
    Value<String>? lightId,
    Value<bool>? isOn,
    Value<int>? brightness,
    Value<int>? kelvin,
    Value<int>? r,
    Value<int>? g,
    Value<int>? b,
    Value<int>? sceneId,
    Value<int>? speed,
    Value<String>? active,
    Value<int?>? rssi,
    Value<int?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LightStatesCompanion(
      lightId: lightId ?? this.lightId,
      isOn: isOn ?? this.isOn,
      brightness: brightness ?? this.brightness,
      kelvin: kelvin ?? this.kelvin,
      r: r ?? this.r,
      g: g ?? this.g,
      b: b ?? this.b,
      sceneId: sceneId ?? this.sceneId,
      speed: speed ?? this.speed,
      active: active ?? this.active,
      rssi: rssi ?? this.rssi,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lightId.present) {
      map['light_id'] = Variable<String>(lightId.value);
    }
    if (isOn.present) {
      map['is_on'] = Variable<bool>(isOn.value);
    }
    if (brightness.present) {
      map['brightness'] = Variable<int>(brightness.value);
    }
    if (kelvin.present) {
      map['kelvin'] = Variable<int>(kelvin.value);
    }
    if (r.present) {
      map['r'] = Variable<int>(r.value);
    }
    if (g.present) {
      map['g'] = Variable<int>(g.value);
    }
    if (b.present) {
      map['b'] = Variable<int>(b.value);
    }
    if (sceneId.present) {
      map['scene_id'] = Variable<int>(sceneId.value);
    }
    if (speed.present) {
      map['speed'] = Variable<int>(speed.value);
    }
    if (active.present) {
      map['active'] = Variable<String>(active.value);
    }
    if (rssi.present) {
      map['rssi'] = Variable<int>(rssi.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LightStatesCompanion(')
          ..write('lightId: $lightId, ')
          ..write('isOn: $isOn, ')
          ..write('brightness: $brightness, ')
          ..write('kelvin: $kelvin, ')
          ..write('r: $r, ')
          ..write('g: $g, ')
          ..write('b: $b, ')
          ..write('sceneId: $sceneId, ')
          ..write('speed: $speed, ')
          ..write('active: $active, ')
          ..write('rssi: $rssi, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HomesTable homes = $HomesTable(this);
  late final $RoomsTable rooms = $RoomsTable(this);
  late final $LightsTable lights = $LightsTable(this);
  late final $LightStatesTable lightStates = $LightStatesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    homes,
    rooms,
    lights,
    lightStates,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'homes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rooms', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'homes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lights', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'lights',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('light_states', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$HomesTableCreateCompanionBuilder = HomesCompanion Function({
  required String id,
  required String name,
  Value<String?> subnet,
  required int createdAt,
  Value<int> sortIndex,
  Value<int> rowid,
});
typedef $$HomesTableUpdateCompanionBuilder = HomesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> subnet,
  Value<int> createdAt,
  Value<int> sortIndex,
  Value<int> rowid,
});

final class $$HomesTableReferences
    extends BaseReferences<_$AppDatabase, $HomesTable, HomeRow> {
  $$HomesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoomsTable, List<RoomRow>> _roomsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rooms,
    aliasName: 'homes__id__rooms__home_id',
  );

  $$RoomsTableProcessedTableManager get roomsRefs {
    final manager = $$RoomsTableTableManager(
      $_db,
      $_db.rooms,
    ).filter((f) => f.homeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_roomsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LightsTable, List<LightRow>> _lightsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.lights,
    aliasName: 'homes__id__lights__home_id',
  );

  $$LightsTableProcessedTableManager get lightsRefs {
    final manager = $$LightsTableTableManager(
      $_db,
      $_db.lights,
    ).filter((f) => f.homeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lightsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HomesTableFilterComposer extends Composer<_$AppDatabase, $HomesTable> {
  $$HomesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subnet => $composableBuilder(
    column: $table.subnet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> roomsRefs(
    Expression<bool> Function($$RoomsTableFilterComposer f) f,
  ) {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.homeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableFilterComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lightsRefs(
    Expression<bool> Function($$LightsTableFilterComposer f) f,
  ) {
    final $$LightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lights,
      getReferencedColumn: (t) => t.homeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LightsTableFilterComposer(
            $db: $db,
            $table: $db.lights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HomesTableOrderingComposer
    extends Composer<_$AppDatabase, $HomesTable> {
  $$HomesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subnet => $composableBuilder(
    column: $table.subnet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HomesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HomesTable> {
  $$HomesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get subnet =>
      $composableBuilder(column: $table.subnet, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  Expression<T> roomsRefs<T extends Object>(
    Expression<T> Function($$RoomsTableAnnotationComposer a) f,
  ) {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.homeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableAnnotationComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lightsRefs<T extends Object>(
    Expression<T> Function($$LightsTableAnnotationComposer a) f,
  ) {
    final $$LightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lights,
      getReferencedColumn: (t) => t.homeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LightsTableAnnotationComposer(
            $db: $db,
            $table: $db.lights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HomesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HomesTable,
          HomeRow,
          $$HomesTableFilterComposer,
          $$HomesTableOrderingComposer,
          $$HomesTableAnnotationComposer,
          $$HomesTableCreateCompanionBuilder,
          $$HomesTableUpdateCompanionBuilder,
          (HomeRow, $$HomesTableReferences),
          HomeRow,
          PrefetchHooks Function({bool roomsRefs, bool lightsRefs})
        > {
  $$HomesTableTableManager(_$AppDatabase db, $HomesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HomesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HomesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HomesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> subnet = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> sortIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HomesCompanion(
                id: id,
                name: name,
                subnet: subnet,
                createdAt: createdAt,
                sortIndex: sortIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> subnet = const Value.absent(),
                required int createdAt,
                Value<int> sortIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HomesCompanion.insert(
                id: id,
                name: name,
                subnet: subnet,
                createdAt: createdAt,
                sortIndex: sortIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HomesTable, HomeRow>(table),
                  $$HomesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({roomsRefs = false, lightsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (roomsRefs) db.rooms,
                if (lightsRefs) db.lights,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (roomsRefs)
                    await $_getPrefetchedData<HomeRow, $HomesTable, RoomRow>(
                      currentTable: table,
                      referencedTable: $$HomesTableReferences._roomsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$HomesTableReferences(db, table, p0).roomsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.homeId == item.id),
                      typedResults: items,
                    ),
                  if (lightsRefs)
                    await $_getPrefetchedData<HomeRow, $HomesTable, LightRow>(
                      currentTable: table,
                      referencedTable: $$HomesTableReferences._lightsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$HomesTableReferences(db, table, p0).lightsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.homeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$HomesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HomesTable,
      HomeRow,
      $$HomesTableFilterComposer,
      $$HomesTableOrderingComposer,
      $$HomesTableAnnotationComposer,
      $$HomesTableCreateCompanionBuilder,
      $$HomesTableUpdateCompanionBuilder,
      (HomeRow, $$HomesTableReferences),
      HomeRow,
      PrefetchHooks Function({bool roomsRefs, bool lightsRefs})
    >;
typedef $$RoomsTableCreateCompanionBuilder = RoomsCompanion Function({
  required String id,
  required String homeId,
  required String name,
  required String glyph,
  Value<int> sortIndex,
  Value<int> rowid,
});
typedef $$RoomsTableUpdateCompanionBuilder = RoomsCompanion Function({
  Value<String> id,
  Value<String> homeId,
  Value<String> name,
  Value<String> glyph,
  Value<int> sortIndex,
  Value<int> rowid,
});

final class $$RoomsTableReferences
    extends BaseReferences<_$AppDatabase, $RoomsTable, RoomRow> {
  $$RoomsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HomesTable _homeIdTable(_$AppDatabase db) =>
      db.homes.createAlias('rooms__home_id__homes__id');

  $$HomesTableProcessedTableManager get homeId {
    final $_column = $_itemColumn<String>('home_id')!;

    final manager = $$HomesTableTableManager(
      $_db,
      $_db.homes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_homeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LightsTable, List<LightRow>> _lightsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.lights,
    aliasName: 'rooms__id__lights__room_id',
  );

  $$LightsTableProcessedTableManager get lightsRefs {
    final manager = $$LightsTableTableManager(
      $_db,
      $_db.lights,
    ).filter((f) => f.roomId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lightsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RoomsTableFilterComposer extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get glyph => $composableBuilder(
    column: $table.glyph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnFilters(column),
  );

  $$HomesTableFilterComposer get homeId {
    final $$HomesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeId,
      referencedTable: $db.homes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomesTableFilterComposer(
            $db: $db,
            $table: $db.homes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> lightsRefs(
    Expression<bool> Function($$LightsTableFilterComposer f) f,
  ) {
    final $$LightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lights,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LightsTableFilterComposer(
            $db: $db,
            $table: $db.lights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoomsTableOrderingComposer
    extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get glyph => $composableBuilder(
    column: $table.glyph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnOrderings(column),
  );

  $$HomesTableOrderingComposer get homeId {
    final $$HomesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeId,
      referencedTable: $db.homes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomesTableOrderingComposer(
            $db: $db,
            $table: $db.homes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get glyph =>
      $composableBuilder(column: $table.glyph, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  $$HomesTableAnnotationComposer get homeId {
    final $$HomesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeId,
      referencedTable: $db.homes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomesTableAnnotationComposer(
            $db: $db,
            $table: $db.homes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> lightsRefs<T extends Object>(
    Expression<T> Function($$LightsTableAnnotationComposer a) f,
  ) {
    final $$LightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lights,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LightsTableAnnotationComposer(
            $db: $db,
            $table: $db.lights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoomsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoomsTable,
          RoomRow,
          $$RoomsTableFilterComposer,
          $$RoomsTableOrderingComposer,
          $$RoomsTableAnnotationComposer,
          $$RoomsTableCreateCompanionBuilder,
          $$RoomsTableUpdateCompanionBuilder,
          (RoomRow, $$RoomsTableReferences),
          RoomRow,
          PrefetchHooks Function({bool homeId, bool lightsRefs})
        > {
  $$RoomsTableTableManager(_$AppDatabase db, $RoomsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> homeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> glyph = const Value.absent(),
                Value<int> sortIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoomsCompanion(
                id: id,
                homeId: homeId,
                name: name,
                glyph: glyph,
                sortIndex: sortIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String homeId,
                required String name,
                required String glyph,
                Value<int> sortIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoomsCompanion.insert(
                id: id,
                homeId: homeId,
                name: name,
                glyph: glyph,
                sortIndex: sortIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RoomsTable, RoomRow>(table),
                  $$RoomsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({homeId = false, lightsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (lightsRefs) db.lights],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (homeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.homeId,
                        referencedTable: $$RoomsTableReferences._homeIdTable(
                          db,
                        ),
                        referencedColumn: $$RoomsTableReferences
                            ._homeIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (lightsRefs)
                    await $_getPrefetchedData<RoomRow, $RoomsTable, LightRow>(
                      currentTable: table,
                      referencedTable: $$RoomsTableReferences._lightsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$RoomsTableReferences(db, table, p0).lightsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.roomId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RoomsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoomsTable,
      RoomRow,
      $$RoomsTableFilterComposer,
      $$RoomsTableOrderingComposer,
      $$RoomsTableAnnotationComposer,
      $$RoomsTableCreateCompanionBuilder,
      $$RoomsTableUpdateCompanionBuilder,
      (RoomRow, $$RoomsTableReferences),
      RoomRow,
      PrefetchHooks Function({bool homeId, bool lightsRefs})
    >;
typedef $$LightsTableCreateCompanionBuilder = LightsCompanion Function({
  required String id,
  required String homeId,
  required String roomId,
  required String name,
  required String ip,
  required String mac,
  Value<String?> moduleName,
  Value<String?> bulbClass,
  required String fixture,
  Value<String?> fwVersion,
  Value<int> sortIndex,
  required int addedAt,
  Value<int> rowid,
});
typedef $$LightsTableUpdateCompanionBuilder = LightsCompanion Function({
  Value<String> id,
  Value<String> homeId,
  Value<String> roomId,
  Value<String> name,
  Value<String> ip,
  Value<String> mac,
  Value<String?> moduleName,
  Value<String?> bulbClass,
  Value<String> fixture,
  Value<String?> fwVersion,
  Value<int> sortIndex,
  Value<int> addedAt,
  Value<int> rowid,
});

final class $$LightsTableReferences
    extends BaseReferences<_$AppDatabase, $LightsTable, LightRow> {
  $$LightsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HomesTable _homeIdTable(_$AppDatabase db) =>
      db.homes.createAlias('lights__home_id__homes__id');

  $$HomesTableProcessedTableManager get homeId {
    final $_column = $_itemColumn<String>('home_id')!;

    final manager = $$HomesTableTableManager(
      $_db,
      $_db.homes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_homeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RoomsTable _roomIdTable(_$AppDatabase db) =>
      db.rooms.createAlias('lights__room_id__rooms__id');

  $$RoomsTableProcessedTableManager get roomId {
    final $_column = $_itemColumn<String>('room_id')!;

    final manager = $$RoomsTableTableManager(
      $_db,
      $_db.rooms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LightStatesTable, List<LightStateRow>>
  _lightStatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lightStates,
    aliasName: 'lights__id__light_states__light_id',
  );

  $$LightStatesTableProcessedTableManager get lightStatesRefs {
    final manager = $$LightStatesTableTableManager(
      $_db,
      $_db.lightStates,
    ).filter((f) => f.lightId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lightStatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LightsTableFilterComposer
    extends Composer<_$AppDatabase, $LightsTable> {
  $$LightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ip => $composableBuilder(
    column: $table.ip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mac => $composableBuilder(
    column: $table.mac,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moduleName => $composableBuilder(
    column: $table.moduleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bulbClass => $composableBuilder(
    column: $table.bulbClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixture => $composableBuilder(
    column: $table.fixture,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fwVersion => $composableBuilder(
    column: $table.fwVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$HomesTableFilterComposer get homeId {
    final $$HomesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeId,
      referencedTable: $db.homes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomesTableFilterComposer(
            $db: $db,
            $table: $db.homes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RoomsTableFilterComposer get roomId {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableFilterComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> lightStatesRefs(
    Expression<bool> Function($$LightStatesTableFilterComposer f) f,
  ) {
    final $$LightStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lightStates,
      getReferencedColumn: (t) => t.lightId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LightStatesTableFilterComposer(
            $db: $db,
            $table: $db.lightStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LightsTableOrderingComposer
    extends Composer<_$AppDatabase, $LightsTable> {
  $$LightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ip => $composableBuilder(
    column: $table.ip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mac => $composableBuilder(
    column: $table.mac,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moduleName => $composableBuilder(
    column: $table.moduleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bulbClass => $composableBuilder(
    column: $table.bulbClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixture => $composableBuilder(
    column: $table.fixture,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fwVersion => $composableBuilder(
    column: $table.fwVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$HomesTableOrderingComposer get homeId {
    final $$HomesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeId,
      referencedTable: $db.homes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomesTableOrderingComposer(
            $db: $db,
            $table: $db.homes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RoomsTableOrderingComposer get roomId {
    final $$RoomsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableOrderingComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LightsTable> {
  $$LightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get ip =>
      $composableBuilder(column: $table.ip, builder: (column) => column);

  GeneratedColumn<String> get mac =>
      $composableBuilder(column: $table.mac, builder: (column) => column);

  GeneratedColumn<String> get moduleName => $composableBuilder(
    column: $table.moduleName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bulbClass =>
      $composableBuilder(column: $table.bulbClass, builder: (column) => column);

  GeneratedColumn<String> get fixture =>
      $composableBuilder(column: $table.fixture, builder: (column) => column);

  GeneratedColumn<String> get fwVersion =>
      $composableBuilder(column: $table.fwVersion, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$HomesTableAnnotationComposer get homeId {
    final $$HomesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeId,
      referencedTable: $db.homes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomesTableAnnotationComposer(
            $db: $db,
            $table: $db.homes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RoomsTableAnnotationComposer get roomId {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableAnnotationComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> lightStatesRefs<T extends Object>(
    Expression<T> Function($$LightStatesTableAnnotationComposer a) f,
  ) {
    final $$LightStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lightStates,
      getReferencedColumn: (t) => t.lightId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LightStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.lightStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LightsTable,
          LightRow,
          $$LightsTableFilterComposer,
          $$LightsTableOrderingComposer,
          $$LightsTableAnnotationComposer,
          $$LightsTableCreateCompanionBuilder,
          $$LightsTableUpdateCompanionBuilder,
          (LightRow, $$LightsTableReferences),
          LightRow,
          PrefetchHooks Function({
            bool homeId,
            bool roomId,
            bool lightStatesRefs,
          })
        > {
  $$LightsTableTableManager(_$AppDatabase db, $LightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> homeId = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> ip = const Value.absent(),
                Value<String> mac = const Value.absent(),
                Value<String?> moduleName = const Value.absent(),
                Value<String?> bulbClass = const Value.absent(),
                Value<String> fixture = const Value.absent(),
                Value<String?> fwVersion = const Value.absent(),
                Value<int> sortIndex = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LightsCompanion(
                id: id,
                homeId: homeId,
                roomId: roomId,
                name: name,
                ip: ip,
                mac: mac,
                moduleName: moduleName,
                bulbClass: bulbClass,
                fixture: fixture,
                fwVersion: fwVersion,
                sortIndex: sortIndex,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String homeId,
                required String roomId,
                required String name,
                required String ip,
                required String mac,
                Value<String?> moduleName = const Value.absent(),
                Value<String?> bulbClass = const Value.absent(),
                required String fixture,
                Value<String?> fwVersion = const Value.absent(),
                Value<int> sortIndex = const Value.absent(),
                required int addedAt,
                Value<int> rowid = const Value.absent(),
              }) => LightsCompanion.insert(
                id: id,
                homeId: homeId,
                roomId: roomId,
                name: name,
                ip: ip,
                mac: mac,
                moduleName: moduleName,
                bulbClass: bulbClass,
                fixture: fixture,
                fwVersion: fwVersion,
                sortIndex: sortIndex,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LightsTable, LightRow>(table),
                  $$LightsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({homeId = false, roomId = false, lightStatesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (lightStatesRefs) db.lightStates,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (homeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.homeId,
                            referencedTable: $$LightsTableReferences
                                ._homeIdTable(db),
                            referencedColumn: $$LightsTableReferences
                                ._homeIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (roomId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.roomId,
                            referencedTable: $$LightsTableReferences
                                ._roomIdTable(db),
                            referencedColumn: $$LightsTableReferences
                                ._roomIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (lightStatesRefs)
                        await $_getPrefetchedData<
                          LightRow,
                          $LightsTable,
                          LightStateRow
                        >(
                          currentTable: table,
                          referencedTable: $$LightsTableReferences
                              ._lightStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LightsTableReferences(
                                db,
                                table,
                                p0,
                              ).lightStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.lightId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LightsTable,
      LightRow,
      $$LightsTableFilterComposer,
      $$LightsTableOrderingComposer,
      $$LightsTableAnnotationComposer,
      $$LightsTableCreateCompanionBuilder,
      $$LightsTableUpdateCompanionBuilder,
      (LightRow, $$LightsTableReferences),
      LightRow,
      PrefetchHooks Function({bool homeId, bool roomId, bool lightStatesRefs})
    >;
typedef $$LightStatesTableCreateCompanionBuilder =
    LightStatesCompanion Function({
      required String lightId,
      required bool isOn,
      required int brightness,
      required int kelvin,
      required int r,
      required int g,
      required int b,
      required int sceneId,
      required int speed,
      required String active,
      Value<int?> rssi,
      Value<int?> updatedAt,
      Value<int> rowid,
    });
typedef $$LightStatesTableUpdateCompanionBuilder =
    LightStatesCompanion Function({
      Value<String> lightId,
      Value<bool> isOn,
      Value<int> brightness,
      Value<int> kelvin,
      Value<int> r,
      Value<int> g,
      Value<int> b,
      Value<int> sceneId,
      Value<int> speed,
      Value<String> active,
      Value<int?> rssi,
      Value<int?> updatedAt,
      Value<int> rowid,
    });

final class $$LightStatesTableReferences
    extends BaseReferences<_$AppDatabase, $LightStatesTable, LightStateRow> {
  $$LightStatesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LightsTable _lightIdTable(_$AppDatabase db) =>
      db.lights.createAlias('light_states__light_id__lights__id');

  $$LightsTableProcessedTableManager get lightId {
    final $_column = $_itemColumn<String>('light_id')!;

    final manager = $$LightsTableTableManager(
      $_db,
      $_db.lights,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lightIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LightStatesTableFilterComposer
    extends Composer<_$AppDatabase, $LightStatesTable> {
  $$LightStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get isOn => $composableBuilder(
    column: $table.isOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get brightness => $composableBuilder(
    column: $table.brightness,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kelvin => $composableBuilder(
    column: $table.kelvin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get r => $composableBuilder(
    column: $table.r,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get g => $composableBuilder(
    column: $table.g,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get b => $composableBuilder(
    column: $table.b,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sceneId => $composableBuilder(
    column: $table.sceneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rssi => $composableBuilder(
    column: $table.rssi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LightsTableFilterComposer get lightId {
    final $$LightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lightId,
      referencedTable: $db.lights,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LightsTableFilterComposer(
            $db: $db,
            $table: $db.lights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LightStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $LightStatesTable> {
  $$LightStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get isOn => $composableBuilder(
    column: $table.isOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get brightness => $composableBuilder(
    column: $table.brightness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kelvin => $composableBuilder(
    column: $table.kelvin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get r => $composableBuilder(
    column: $table.r,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get g => $composableBuilder(
    column: $table.g,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get b => $composableBuilder(
    column: $table.b,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sceneId => $composableBuilder(
    column: $table.sceneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rssi => $composableBuilder(
    column: $table.rssi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LightsTableOrderingComposer get lightId {
    final $$LightsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lightId,
      referencedTable: $db.lights,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LightsTableOrderingComposer(
            $db: $db,
            $table: $db.lights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LightStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LightStatesTable> {
  $$LightStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get isOn =>
      $composableBuilder(column: $table.isOn, builder: (column) => column);

  GeneratedColumn<int> get brightness => $composableBuilder(
    column: $table.brightness,
    builder: (column) => column,
  );

  GeneratedColumn<int> get kelvin =>
      $composableBuilder(column: $table.kelvin, builder: (column) => column);

  GeneratedColumn<int> get r =>
      $composableBuilder(column: $table.r, builder: (column) => column);

  GeneratedColumn<int> get g =>
      $composableBuilder(column: $table.g, builder: (column) => column);

  GeneratedColumn<int> get b =>
      $composableBuilder(column: $table.b, builder: (column) => column);

  GeneratedColumn<int> get sceneId =>
      $composableBuilder(column: $table.sceneId, builder: (column) => column);

  GeneratedColumn<int> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<String> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get rssi =>
      $composableBuilder(column: $table.rssi, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LightsTableAnnotationComposer get lightId {
    final $$LightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lightId,
      referencedTable: $db.lights,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LightsTableAnnotationComposer(
            $db: $db,
            $table: $db.lights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LightStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LightStatesTable,
          LightStateRow,
          $$LightStatesTableFilterComposer,
          $$LightStatesTableOrderingComposer,
          $$LightStatesTableAnnotationComposer,
          $$LightStatesTableCreateCompanionBuilder,
          $$LightStatesTableUpdateCompanionBuilder,
          (LightStateRow, $$LightStatesTableReferences),
          LightStateRow,
          PrefetchHooks Function({bool lightId})
        > {
  $$LightStatesTableTableManager(_$AppDatabase db, $LightStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LightStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LightStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LightStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lightId = const Value.absent(),
                Value<bool> isOn = const Value.absent(),
                Value<int> brightness = const Value.absent(),
                Value<int> kelvin = const Value.absent(),
                Value<int> r = const Value.absent(),
                Value<int> g = const Value.absent(),
                Value<int> b = const Value.absent(),
                Value<int> sceneId = const Value.absent(),
                Value<int> speed = const Value.absent(),
                Value<String> active = const Value.absent(),
                Value<int?> rssi = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LightStatesCompanion(
                lightId: lightId,
                isOn: isOn,
                brightness: brightness,
                kelvin: kelvin,
                r: r,
                g: g,
                b: b,
                sceneId: sceneId,
                speed: speed,
                active: active,
                rssi: rssi,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lightId,
                required bool isOn,
                required int brightness,
                required int kelvin,
                required int r,
                required int g,
                required int b,
                required int sceneId,
                required int speed,
                required String active,
                Value<int?> rssi = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LightStatesCompanion.insert(
                lightId: lightId,
                isOn: isOn,
                brightness: brightness,
                kelvin: kelvin,
                r: r,
                g: g,
                b: b,
                sceneId: sceneId,
                speed: speed,
                active: active,
                rssi: rssi,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LightStatesTable, LightStateRow>(table),
                  $$LightStatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({lightId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (lightId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.lightId,
                        referencedTable: $$LightStatesTableReferences
                            ._lightIdTable(db),
                        referencedColumn: $$LightStatesTableReferences
                            ._lightIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LightStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LightStatesTable,
      LightStateRow,
      $$LightStatesTableFilterComposer,
      $$LightStatesTableOrderingComposer,
      $$LightStatesTableAnnotationComposer,
      $$LightStatesTableCreateCompanionBuilder,
      $$LightStatesTableUpdateCompanionBuilder,
      (LightStateRow, $$LightStatesTableReferences),
      LightStateRow,
      PrefetchHooks Function({bool lightId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HomesTableTableManager get homes =>
      $$HomesTableTableManager(_db, _db.homes);
  $$RoomsTableTableManager get rooms =>
      $$RoomsTableTableManager(_db, _db.rooms);
  $$LightsTableTableManager get lights =>
      $$LightsTableTableManager(_db, _db.lights);
  $$LightStatesTableTableManager get lightStates =>
      $$LightStatesTableTableManager(_db, _db.lightStates);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
