// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UserFilmsTable extends UserFilms
    with TableInfo<$UserFilmsTable, UserFilmRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserFilmsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boxIsoMeta = const VerificationMeta('boxIso');
  @override
  late final GeneratedColumn<int> boxIso = GeneratedColumn<int>(
    'box_iso',
    aliasedName,
    false,
    check: () => ComparableExpr(boxIso).isBetweenValues(1, 25600),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchedCatalogIdMeta = const VerificationMeta(
    'matchedCatalogId',
  );
  @override
  late final GeneratedColumn<String> matchedCatalogId = GeneratedColumn<String>(
    'matched_catalog_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    brand,
    name,
    boxIso,
    matchedCatalogId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_films';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserFilmRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    } else if (isInserting) {
      context.missing(_brandMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('box_iso')) {
      context.handle(
        _boxIsoMeta,
        boxIso.isAcceptableOrUnknown(data['box_iso']!, _boxIsoMeta),
      );
    } else if (isInserting) {
      context.missing(_boxIsoMeta);
    }
    if (data.containsKey('matched_catalog_id')) {
      context.handle(
        _matchedCatalogIdMeta,
        matchedCatalogId.isAcceptableOrUnknown(
          data['matched_catalog_id']!,
          _matchedCatalogIdMeta,
        ),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserFilmRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserFilmRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      boxIso: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}box_iso'],
      )!,
      matchedCatalogId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matched_catalog_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserFilmsTable createAlias(String alias) {
    return $UserFilmsTable(attachedDatabase, alias);
  }
}

class UserFilmRow extends DataClass implements Insertable<UserFilmRow> {
  final String id;
  final String brand;
  final String name;
  final int boxIso;
  final String? matchedCatalogId;
  final DateTime createdAt;
  const UserFilmRow({
    required this.id,
    required this.brand,
    required this.name,
    required this.boxIso,
    this.matchedCatalogId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['brand'] = Variable<String>(brand);
    map['name'] = Variable<String>(name);
    map['box_iso'] = Variable<int>(boxIso);
    if (!nullToAbsent || matchedCatalogId != null) {
      map['matched_catalog_id'] = Variable<String>(matchedCatalogId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserFilmsCompanion toCompanion(bool nullToAbsent) {
    return UserFilmsCompanion(
      id: Value(id),
      brand: Value(brand),
      name: Value(name),
      boxIso: Value(boxIso),
      matchedCatalogId: matchedCatalogId == null && nullToAbsent
          ? const Value.absent()
          : Value(matchedCatalogId),
      createdAt: Value(createdAt),
    );
  }

  factory UserFilmRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserFilmRow(
      id: serializer.fromJson<String>(json['id']),
      brand: serializer.fromJson<String>(json['brand']),
      name: serializer.fromJson<String>(json['name']),
      boxIso: serializer.fromJson<int>(json['boxIso']),
      matchedCatalogId: serializer.fromJson<String?>(json['matchedCatalogId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'brand': serializer.toJson<String>(brand),
      'name': serializer.toJson<String>(name),
      'boxIso': serializer.toJson<int>(boxIso),
      'matchedCatalogId': serializer.toJson<String?>(matchedCatalogId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserFilmRow copyWith({
    String? id,
    String? brand,
    String? name,
    int? boxIso,
    Value<String?> matchedCatalogId = const Value.absent(),
    DateTime? createdAt,
  }) => UserFilmRow(
    id: id ?? this.id,
    brand: brand ?? this.brand,
    name: name ?? this.name,
    boxIso: boxIso ?? this.boxIso,
    matchedCatalogId: matchedCatalogId.present
        ? matchedCatalogId.value
        : this.matchedCatalogId,
    createdAt: createdAt ?? this.createdAt,
  );
  UserFilmRow copyWithCompanion(UserFilmsCompanion data) {
    return UserFilmRow(
      id: data.id.present ? data.id.value : this.id,
      brand: data.brand.present ? data.brand.value : this.brand,
      name: data.name.present ? data.name.value : this.name,
      boxIso: data.boxIso.present ? data.boxIso.value : this.boxIso,
      matchedCatalogId: data.matchedCatalogId.present
          ? data.matchedCatalogId.value
          : this.matchedCatalogId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserFilmRow(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('name: $name, ')
          ..write('boxIso: $boxIso, ')
          ..write('matchedCatalogId: $matchedCatalogId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, brand, name, boxIso, matchedCatalogId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserFilmRow &&
          other.id == this.id &&
          other.brand == this.brand &&
          other.name == this.name &&
          other.boxIso == this.boxIso &&
          other.matchedCatalogId == this.matchedCatalogId &&
          other.createdAt == this.createdAt);
}

class UserFilmsCompanion extends UpdateCompanion<UserFilmRow> {
  final Value<String> id;
  final Value<String> brand;
  final Value<String> name;
  final Value<int> boxIso;
  final Value<String?> matchedCatalogId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UserFilmsCompanion({
    this.id = const Value.absent(),
    this.brand = const Value.absent(),
    this.name = const Value.absent(),
    this.boxIso = const Value.absent(),
    this.matchedCatalogId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserFilmsCompanion.insert({
    required String id,
    required String brand,
    required String name,
    required int boxIso,
    this.matchedCatalogId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       brand = Value(brand),
       name = Value(name),
       boxIso = Value(boxIso),
       createdAt = Value(createdAt);
  static Insertable<UserFilmRow> custom({
    Expression<String>? id,
    Expression<String>? brand,
    Expression<String>? name,
    Expression<int>? boxIso,
    Expression<String>? matchedCatalogId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brand != null) 'brand': brand,
      if (name != null) 'name': name,
      if (boxIso != null) 'box_iso': boxIso,
      if (matchedCatalogId != null) 'matched_catalog_id': matchedCatalogId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserFilmsCompanion copyWith({
    Value<String>? id,
    Value<String>? brand,
    Value<String>? name,
    Value<int>? boxIso,
    Value<String?>? matchedCatalogId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return UserFilmsCompanion(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      name: name ?? this.name,
      boxIso: boxIso ?? this.boxIso,
      matchedCatalogId: matchedCatalogId ?? this.matchedCatalogId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (boxIso.present) {
      map['box_iso'] = Variable<int>(boxIso.value);
    }
    if (matchedCatalogId.present) {
      map['matched_catalog_id'] = Variable<String>(matchedCatalogId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserFilmsCompanion(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('name: $name, ')
          ..write('boxIso: $boxIso, ')
          ..write('matchedCatalogId: $matchedCatalogId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserDevelopersTable extends UserDevelopers
    with TableInfo<$UserDevelopersTable, UserDeveloperRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserDevelopersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchedCatalogIdMeta = const VerificationMeta(
    'matchedCatalogId',
  );
  @override
  late final GeneratedColumn<String> matchedCatalogId = GeneratedColumn<String>(
    'matched_catalog_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    brand,
    name,
    matchedCatalogId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_developers';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserDeveloperRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    } else if (isInserting) {
      context.missing(_brandMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('matched_catalog_id')) {
      context.handle(
        _matchedCatalogIdMeta,
        matchedCatalogId.isAcceptableOrUnknown(
          data['matched_catalog_id']!,
          _matchedCatalogIdMeta,
        ),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserDeveloperRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserDeveloperRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      matchedCatalogId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matched_catalog_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UserDevelopersTable createAlias(String alias) {
    return $UserDevelopersTable(attachedDatabase, alias);
  }
}

class UserDeveloperRow extends DataClass
    implements Insertable<UserDeveloperRow> {
  final String id;
  final String brand;
  final String name;
  final String? matchedCatalogId;
  final DateTime createdAt;
  const UserDeveloperRow({
    required this.id,
    required this.brand,
    required this.name,
    this.matchedCatalogId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['brand'] = Variable<String>(brand);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || matchedCatalogId != null) {
      map['matched_catalog_id'] = Variable<String>(matchedCatalogId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserDevelopersCompanion toCompanion(bool nullToAbsent) {
    return UserDevelopersCompanion(
      id: Value(id),
      brand: Value(brand),
      name: Value(name),
      matchedCatalogId: matchedCatalogId == null && nullToAbsent
          ? const Value.absent()
          : Value(matchedCatalogId),
      createdAt: Value(createdAt),
    );
  }

  factory UserDeveloperRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserDeveloperRow(
      id: serializer.fromJson<String>(json['id']),
      brand: serializer.fromJson<String>(json['brand']),
      name: serializer.fromJson<String>(json['name']),
      matchedCatalogId: serializer.fromJson<String?>(json['matchedCatalogId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'brand': serializer.toJson<String>(brand),
      'name': serializer.toJson<String>(name),
      'matchedCatalogId': serializer.toJson<String?>(matchedCatalogId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserDeveloperRow copyWith({
    String? id,
    String? brand,
    String? name,
    Value<String?> matchedCatalogId = const Value.absent(),
    DateTime? createdAt,
  }) => UserDeveloperRow(
    id: id ?? this.id,
    brand: brand ?? this.brand,
    name: name ?? this.name,
    matchedCatalogId: matchedCatalogId.present
        ? matchedCatalogId.value
        : this.matchedCatalogId,
    createdAt: createdAt ?? this.createdAt,
  );
  UserDeveloperRow copyWithCompanion(UserDevelopersCompanion data) {
    return UserDeveloperRow(
      id: data.id.present ? data.id.value : this.id,
      brand: data.brand.present ? data.brand.value : this.brand,
      name: data.name.present ? data.name.value : this.name,
      matchedCatalogId: data.matchedCatalogId.present
          ? data.matchedCatalogId.value
          : this.matchedCatalogId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserDeveloperRow(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('name: $name, ')
          ..write('matchedCatalogId: $matchedCatalogId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, brand, name, matchedCatalogId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserDeveloperRow &&
          other.id == this.id &&
          other.brand == this.brand &&
          other.name == this.name &&
          other.matchedCatalogId == this.matchedCatalogId &&
          other.createdAt == this.createdAt);
}

class UserDevelopersCompanion extends UpdateCompanion<UserDeveloperRow> {
  final Value<String> id;
  final Value<String> brand;
  final Value<String> name;
  final Value<String?> matchedCatalogId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UserDevelopersCompanion({
    this.id = const Value.absent(),
    this.brand = const Value.absent(),
    this.name = const Value.absent(),
    this.matchedCatalogId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserDevelopersCompanion.insert({
    required String id,
    required String brand,
    required String name,
    this.matchedCatalogId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       brand = Value(brand),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<UserDeveloperRow> custom({
    Expression<String>? id,
    Expression<String>? brand,
    Expression<String>? name,
    Expression<String>? matchedCatalogId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brand != null) 'brand': brand,
      if (name != null) 'name': name,
      if (matchedCatalogId != null) 'matched_catalog_id': matchedCatalogId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserDevelopersCompanion copyWith({
    Value<String>? id,
    Value<String>? brand,
    Value<String>? name,
    Value<String?>? matchedCatalogId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return UserDevelopersCompanion(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      name: name ?? this.name,
      matchedCatalogId: matchedCatalogId ?? this.matchedCatalogId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (matchedCatalogId.present) {
      map['matched_catalog_id'] = Variable<String>(matchedCatalogId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserDevelopersCompanion(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('name: $name, ')
          ..write('matchedCatalogId: $matchedCatalogId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipesTable extends Recipes with TableInfo<$RecipesTable, RecipeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    check: () => ComparableExpr(version).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorNameMeta = const VerificationMeta(
    'authorName',
  );
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
    'author_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownershipMeta = const VerificationMeta(
    'ownership',
  );
  @override
  late final GeneratedColumn<String> ownership = GeneratedColumn<String>(
    'ownership',
    aliasedName,
    false,
    check: () => ownership.isIn(['own', 'received']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originJsonMeta = const VerificationMeta(
    'originJson',
  );
  @override
  late final GeneratedColumn<String> originJson = GeneratedColumn<String>(
    'origin_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keyCanonicalMeta = const VerificationMeta(
    'keyCanonical',
  );
  @override
  late final GeneratedColumn<String> keyCanonical = GeneratedColumn<String>(
    'key_canonical',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyJsonMeta = const VerificationMeta(
    'keyJson',
  );
  @override
  late final GeneratedColumn<String> keyJson = GeneratedColumn<String>(
    'key_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _devTimeSMeta = const VerificationMeta(
    'devTimeS',
  );
  @override
  late final GeneratedColumn<int> devTimeS = GeneratedColumn<int>(
    'dev_time_s',
    aliasedName,
    false,
    check: () => ComparableExpr(devTimeS).isBetweenValues(30, 7200),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _devAgitationJsonMeta = const VerificationMeta(
    'devAgitationJson',
  );
  @override
  late final GeneratedColumn<String> devAgitationJson = GeneratedColumn<String>(
    'dev_agitation_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processJsonMeta = const VerificationMeta(
    'processJson',
  );
  @override
  late final GeneratedColumn<String> processJson = GeneratedColumn<String>(
    'process_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    version,
    createdAt,
    updatedAt,
    authorName,
    ownership,
    originJson,
    importedAt,
    keyCanonical,
    keyJson,
    devTimeS,
    devAgitationJson,
    processJson,
    hidden,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('author_name')) {
      context.handle(
        _authorNameMeta,
        authorName.isAcceptableOrUnknown(data['author_name']!, _authorNameMeta),
      );
    } else if (isInserting) {
      context.missing(_authorNameMeta);
    }
    if (data.containsKey('ownership')) {
      context.handle(
        _ownershipMeta,
        ownership.isAcceptableOrUnknown(data['ownership']!, _ownershipMeta),
      );
    } else if (isInserting) {
      context.missing(_ownershipMeta);
    }
    if (data.containsKey('origin_json')) {
      context.handle(
        _originJsonMeta,
        originJson.isAcceptableOrUnknown(data['origin_json']!, _originJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_originJsonMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    }
    if (data.containsKey('key_canonical')) {
      context.handle(
        _keyCanonicalMeta,
        keyCanonical.isAcceptableOrUnknown(
          data['key_canonical']!,
          _keyCanonicalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keyCanonicalMeta);
    }
    if (data.containsKey('key_json')) {
      context.handle(
        _keyJsonMeta,
        keyJson.isAcceptableOrUnknown(data['key_json']!, _keyJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_keyJsonMeta);
    }
    if (data.containsKey('dev_time_s')) {
      context.handle(
        _devTimeSMeta,
        devTimeS.isAcceptableOrUnknown(data['dev_time_s']!, _devTimeSMeta),
      );
    } else if (isInserting) {
      context.missing(_devTimeSMeta);
    }
    if (data.containsKey('dev_agitation_json')) {
      context.handle(
        _devAgitationJsonMeta,
        devAgitationJson.isAcceptableOrUnknown(
          data['dev_agitation_json']!,
          _devAgitationJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_devAgitationJsonMeta);
    }
    if (data.containsKey('process_json')) {
      context.handle(
        _processJsonMeta,
        processJson.isAcceptableOrUnknown(
          data['process_json']!,
          _processJsonMeta,
        ),
      );
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      authorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_name'],
      )!,
      ownership: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ownership'],
      )!,
      originJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_json'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      ),
      keyCanonical: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_canonical'],
      )!,
      keyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_json'],
      )!,
      devTimeS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dev_time_s'],
      )!,
      devAgitationJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dev_agitation_json'],
      )!,
      processJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}process_json'],
      ),
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }
}

class RecipeRow extends DataClass implements Insertable<RecipeRow> {
  final String id;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String authorName;
  final String ownership;
  final String originJson;
  final DateTime? importedAt;
  final String keyCanonical;
  final String keyJson;
  final int devTimeS;
  final String devAgitationJson;
  final String? processJson;
  final bool hidden;
  const RecipeRow({
    required this.id,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.authorName,
    required this.ownership,
    required this.originJson,
    this.importedAt,
    required this.keyCanonical,
    required this.keyJson,
    required this.devTimeS,
    required this.devAgitationJson,
    this.processJson,
    required this.hidden,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['author_name'] = Variable<String>(authorName);
    map['ownership'] = Variable<String>(ownership);
    map['origin_json'] = Variable<String>(originJson);
    if (!nullToAbsent || importedAt != null) {
      map['imported_at'] = Variable<DateTime>(importedAt);
    }
    map['key_canonical'] = Variable<String>(keyCanonical);
    map['key_json'] = Variable<String>(keyJson);
    map['dev_time_s'] = Variable<int>(devTimeS);
    map['dev_agitation_json'] = Variable<String>(devAgitationJson);
    if (!nullToAbsent || processJson != null) {
      map['process_json'] = Variable<String>(processJson);
    }
    map['hidden'] = Variable<bool>(hidden);
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: Value(id),
      version: Value(version),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      authorName: Value(authorName),
      ownership: Value(ownership),
      originJson: Value(originJson),
      importedAt: importedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(importedAt),
      keyCanonical: Value(keyCanonical),
      keyJson: Value(keyJson),
      devTimeS: Value(devTimeS),
      devAgitationJson: Value(devAgitationJson),
      processJson: processJson == null && nullToAbsent
          ? const Value.absent()
          : Value(processJson),
      hidden: Value(hidden),
    );
  }

  factory RecipeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeRow(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      authorName: serializer.fromJson<String>(json['authorName']),
      ownership: serializer.fromJson<String>(json['ownership']),
      originJson: serializer.fromJson<String>(json['originJson']),
      importedAt: serializer.fromJson<DateTime?>(json['importedAt']),
      keyCanonical: serializer.fromJson<String>(json['keyCanonical']),
      keyJson: serializer.fromJson<String>(json['keyJson']),
      devTimeS: serializer.fromJson<int>(json['devTimeS']),
      devAgitationJson: serializer.fromJson<String>(json['devAgitationJson']),
      processJson: serializer.fromJson<String?>(json['processJson']),
      hidden: serializer.fromJson<bool>(json['hidden']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'authorName': serializer.toJson<String>(authorName),
      'ownership': serializer.toJson<String>(ownership),
      'originJson': serializer.toJson<String>(originJson),
      'importedAt': serializer.toJson<DateTime?>(importedAt),
      'keyCanonical': serializer.toJson<String>(keyCanonical),
      'keyJson': serializer.toJson<String>(keyJson),
      'devTimeS': serializer.toJson<int>(devTimeS),
      'devAgitationJson': serializer.toJson<String>(devAgitationJson),
      'processJson': serializer.toJson<String?>(processJson),
      'hidden': serializer.toJson<bool>(hidden),
    };
  }

  RecipeRow copyWith({
    String? id,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorName,
    String? ownership,
    String? originJson,
    Value<DateTime?> importedAt = const Value.absent(),
    String? keyCanonical,
    String? keyJson,
    int? devTimeS,
    String? devAgitationJson,
    Value<String?> processJson = const Value.absent(),
    bool? hidden,
  }) => RecipeRow(
    id: id ?? this.id,
    version: version ?? this.version,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    authorName: authorName ?? this.authorName,
    ownership: ownership ?? this.ownership,
    originJson: originJson ?? this.originJson,
    importedAt: importedAt.present ? importedAt.value : this.importedAt,
    keyCanonical: keyCanonical ?? this.keyCanonical,
    keyJson: keyJson ?? this.keyJson,
    devTimeS: devTimeS ?? this.devTimeS,
    devAgitationJson: devAgitationJson ?? this.devAgitationJson,
    processJson: processJson.present ? processJson.value : this.processJson,
    hidden: hidden ?? this.hidden,
  );
  RecipeRow copyWithCompanion(RecipesCompanion data) {
    return RecipeRow(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      authorName: data.authorName.present
          ? data.authorName.value
          : this.authorName,
      ownership: data.ownership.present ? data.ownership.value : this.ownership,
      originJson: data.originJson.present
          ? data.originJson.value
          : this.originJson,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      keyCanonical: data.keyCanonical.present
          ? data.keyCanonical.value
          : this.keyCanonical,
      keyJson: data.keyJson.present ? data.keyJson.value : this.keyJson,
      devTimeS: data.devTimeS.present ? data.devTimeS.value : this.devTimeS,
      devAgitationJson: data.devAgitationJson.present
          ? data.devAgitationJson.value
          : this.devAgitationJson,
      processJson: data.processJson.present
          ? data.processJson.value
          : this.processJson,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeRow(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('authorName: $authorName, ')
          ..write('ownership: $ownership, ')
          ..write('originJson: $originJson, ')
          ..write('importedAt: $importedAt, ')
          ..write('keyCanonical: $keyCanonical, ')
          ..write('keyJson: $keyJson, ')
          ..write('devTimeS: $devTimeS, ')
          ..write('devAgitationJson: $devAgitationJson, ')
          ..write('processJson: $processJson, ')
          ..write('hidden: $hidden')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    version,
    createdAt,
    updatedAt,
    authorName,
    ownership,
    originJson,
    importedAt,
    keyCanonical,
    keyJson,
    devTimeS,
    devAgitationJson,
    processJson,
    hidden,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeRow &&
          other.id == this.id &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.authorName == this.authorName &&
          other.ownership == this.ownership &&
          other.originJson == this.originJson &&
          other.importedAt == this.importedAt &&
          other.keyCanonical == this.keyCanonical &&
          other.keyJson == this.keyJson &&
          other.devTimeS == this.devTimeS &&
          other.devAgitationJson == this.devAgitationJson &&
          other.processJson == this.processJson &&
          other.hidden == this.hidden);
}

class RecipesCompanion extends UpdateCompanion<RecipeRow> {
  final Value<String> id;
  final Value<int> version;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> authorName;
  final Value<String> ownership;
  final Value<String> originJson;
  final Value<DateTime?> importedAt;
  final Value<String> keyCanonical;
  final Value<String> keyJson;
  final Value<int> devTimeS;
  final Value<String> devAgitationJson;
  final Value<String?> processJson;
  final Value<bool> hidden;
  final Value<int> rowid;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.authorName = const Value.absent(),
    this.ownership = const Value.absent(),
    this.originJson = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.keyCanonical = const Value.absent(),
    this.keyJson = const Value.absent(),
    this.devTimeS = const Value.absent(),
    this.devAgitationJson = const Value.absent(),
    this.processJson = const Value.absent(),
    this.hidden = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipesCompanion.insert({
    required String id,
    required int version,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String authorName,
    required String ownership,
    required String originJson,
    this.importedAt = const Value.absent(),
    required String keyCanonical,
    required String keyJson,
    required int devTimeS,
    required String devAgitationJson,
    this.processJson = const Value.absent(),
    this.hidden = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       version = Value(version),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       authorName = Value(authorName),
       ownership = Value(ownership),
       originJson = Value(originJson),
       keyCanonical = Value(keyCanonical),
       keyJson = Value(keyJson),
       devTimeS = Value(devTimeS),
       devAgitationJson = Value(devAgitationJson);
  static Insertable<RecipeRow> custom({
    Expression<String>? id,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? authorName,
    Expression<String>? ownership,
    Expression<String>? originJson,
    Expression<DateTime>? importedAt,
    Expression<String>? keyCanonical,
    Expression<String>? keyJson,
    Expression<int>? devTimeS,
    Expression<String>? devAgitationJson,
    Expression<String>? processJson,
    Expression<bool>? hidden,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (authorName != null) 'author_name': authorName,
      if (ownership != null) 'ownership': ownership,
      if (originJson != null) 'origin_json': originJson,
      if (importedAt != null) 'imported_at': importedAt,
      if (keyCanonical != null) 'key_canonical': keyCanonical,
      if (keyJson != null) 'key_json': keyJson,
      if (devTimeS != null) 'dev_time_s': devTimeS,
      if (devAgitationJson != null) 'dev_agitation_json': devAgitationJson,
      if (processJson != null) 'process_json': processJson,
      if (hidden != null) 'hidden': hidden,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipesCompanion copyWith({
    Value<String>? id,
    Value<int>? version,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? authorName,
    Value<String>? ownership,
    Value<String>? originJson,
    Value<DateTime?>? importedAt,
    Value<String>? keyCanonical,
    Value<String>? keyJson,
    Value<int>? devTimeS,
    Value<String>? devAgitationJson,
    Value<String?>? processJson,
    Value<bool>? hidden,
    Value<int>? rowid,
  }) {
    return RecipesCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorName: authorName ?? this.authorName,
      ownership: ownership ?? this.ownership,
      originJson: originJson ?? this.originJson,
      importedAt: importedAt ?? this.importedAt,
      keyCanonical: keyCanonical ?? this.keyCanonical,
      keyJson: keyJson ?? this.keyJson,
      devTimeS: devTimeS ?? this.devTimeS,
      devAgitationJson: devAgitationJson ?? this.devAgitationJson,
      processJson: processJson ?? this.processJson,
      hidden: hidden ?? this.hidden,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (ownership.present) {
      map['ownership'] = Variable<String>(ownership.value);
    }
    if (originJson.present) {
      map['origin_json'] = Variable<String>(originJson.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (keyCanonical.present) {
      map['key_canonical'] = Variable<String>(keyCanonical.value);
    }
    if (keyJson.present) {
      map['key_json'] = Variable<String>(keyJson.value);
    }
    if (devTimeS.present) {
      map['dev_time_s'] = Variable<int>(devTimeS.value);
    }
    if (devAgitationJson.present) {
      map['dev_agitation_json'] = Variable<String>(devAgitationJson.value);
    }
    if (processJson.present) {
      map['process_json'] = Variable<String>(processJson.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('authorName: $authorName, ')
          ..write('ownership: $ownership, ')
          ..write('originJson: $originJson, ')
          ..write('importedAt: $importedAt, ')
          ..write('keyCanonical: $keyCanonical, ')
          ..write('keyJson: $keyJson, ')
          ..write('devTimeS: $devTimeS, ')
          ..write('devAgitationJson: $devAgitationJson, ')
          ..write('processJson: $processJson, ')
          ..write('hidden: $hidden, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id)',
    ),
  );
  static const VerificationMeta _authorNameMeta = const VerificationMeta(
    'authorName',
  );
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
    'author_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _text_Meta = const VerificationMeta('text_');
  @override
  late final GeneratedColumn<String> text_ = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 4000,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recipeId,
    authorName,
    createdAt,
    text_,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('author_name')) {
      context.handle(
        _authorNameMeta,
        authorName.isAcceptableOrUnknown(data['author_name']!, _authorNameMeta),
      );
    } else if (isInserting) {
      context.missing(_authorNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _text_Meta,
        text_.isAcceptableOrUnknown(data['text']!, _text_Meta),
      );
    } else if (isInserting) {
      context.missing(_text_Meta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      authorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      text_: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final String id;
  final String recipeId;
  final String authorName;
  final DateTime createdAt;
  final String text_;
  const NoteRow({
    required this.id,
    required this.recipeId,
    required this.authorName,
    required this.createdAt,
    required this.text_,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    map['author_name'] = Variable<String>(authorName);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['text'] = Variable<String>(text_);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      authorName: Value(authorName),
      createdAt: Value(createdAt),
      text_: Value(text_),
    );
  }

  factory NoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      authorName: serializer.fromJson<String>(json['authorName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      text_: serializer.fromJson<String>(json['text_']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'authorName': serializer.toJson<String>(authorName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'text_': serializer.toJson<String>(text_),
    };
  }

  NoteRow copyWith({
    String? id,
    String? recipeId,
    String? authorName,
    DateTime? createdAt,
    String? text_,
  }) => NoteRow(
    id: id ?? this.id,
    recipeId: recipeId ?? this.recipeId,
    authorName: authorName ?? this.authorName,
    createdAt: createdAt ?? this.createdAt,
    text_: text_ ?? this.text_,
  );
  NoteRow copyWithCompanion(NotesCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      authorName: data.authorName.present
          ? data.authorName.value
          : this.authorName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      text_: data.text_.present ? data.text_.value : this.text_,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('authorName: $authorName, ')
          ..write('createdAt: $createdAt, ')
          ..write('text_: $text_')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recipeId, authorName, createdAt, text_);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.authorName == this.authorName &&
          other.createdAt == this.createdAt &&
          other.text_ == this.text_);
}

class NotesCompanion extends UpdateCompanion<NoteRow> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<String> authorName;
  final Value<DateTime> createdAt;
  final Value<String> text_;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.authorName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.text_ = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    required String recipeId,
    required String authorName,
    required DateTime createdAt,
    required String text_,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recipeId = Value(recipeId),
       authorName = Value(authorName),
       createdAt = Value(createdAt),
       text_ = Value(text_);
  static Insertable<NoteRow> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<String>? authorName,
    Expression<DateTime>? createdAt,
    Expression<String>? text_,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (authorName != null) 'author_name': authorName,
      if (createdAt != null) 'created_at': createdAt,
      if (text_ != null) 'text': text_,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String>? recipeId,
    Value<String>? authorName,
    Value<DateTime>? createdAt,
    Value<String>? text_,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      text_: text_ ?? this.text_,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (text_.present) {
      map['text'] = Variable<String>(text_.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('authorName: $authorName, ')
          ..write('createdAt: $createdAt, ')
          ..write('text_: $text_, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProcessesTable extends Processes
    with TableInfo<$ProcessesTable, ProcessesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProcessesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'processes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProcessesData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProcessesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProcessesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $ProcessesTable createAlias(String alias) {
    return $ProcessesTable(attachedDatabase, alias);
  }
}

class ProcessesData extends DataClass implements Insertable<ProcessesData> {
  final String id;
  final String json;
  const ProcessesData({required this.id, required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    return map;
  }

  ProcessesCompanion toCompanion(bool nullToAbsent) {
    return ProcessesCompanion(id: Value(id), json: Value(json));
  }

  factory ProcessesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProcessesData(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
    };
  }

  ProcessesData copyWith({String? id, String? json}) =>
      ProcessesData(id: id ?? this.id, json: json ?? this.json);
  ProcessesData copyWithCompanion(ProcessesCompanion data) {
    return ProcessesData(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProcessesData(')
          ..write('id: $id, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProcessesData &&
          other.id == this.id &&
          other.json == this.json);
}

class ProcessesCompanion extends UpdateCompanion<ProcessesData> {
  final Value<String> id;
  final Value<String> json;
  final Value<int> rowid;
  const ProcessesCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProcessesCompanion.insert({
    required String id,
    required String json,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json);
  static Insertable<ProcessesData> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProcessesCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return ProcessesCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProcessesCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tankSlotMeta = const VerificationMeta(
    'tankSlot',
  );
  @override
  late final GeneratedColumn<int> tankSlot = GeneratedColumn<int>(
    'tank_slot',
    aliasedName,
    false,
    check: () => ComparableExpr(tankSlot).isBetweenValues(1, 3),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tankLabelMeta = const VerificationMeta(
    'tankLabel',
  );
  @override
  late final GeneratedColumn<String> tankLabel = GeneratedColumn<String>(
    'tank_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyCanonicalMeta = const VerificationMeta(
    'keyCanonical',
  );
  @override
  late final GeneratedColumn<String> keyCanonical = GeneratedColumn<String>(
    'key_canonical',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keyJsonMeta = const VerificationMeta(
    'keyJson',
  );
  @override
  late final GeneratedColumn<String> keyJson = GeneratedColumn<String>(
    'key_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeSourceJsonMeta = const VerificationMeta(
    'timeSourceJson',
  );
  @override
  late final GeneratedColumn<String> timeSourceJson = GeneratedColumn<String>(
    'time_source_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _devTimeSMeta = const VerificationMeta(
    'devTimeS',
  );
  @override
  late final GeneratedColumn<int> devTimeS = GeneratedColumn<int>(
    'dev_time_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    check: () => format.isIn(['35mm', '120']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _volumeMlMeta = const VerificationMeta(
    'volumeMl',
  );
  @override
  late final GeneratedColumn<int> volumeMl = GeneratedColumn<int>(
    'volume_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processSnapshotJsonMeta =
      const VerificationMeta('processSnapshotJson');
  @override
  late final GeneratedColumn<String> processSnapshotJson =
      GeneratedColumn<String>(
        'process_snapshot_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _inversionPaceSMeta = const VerificationMeta(
    'inversionPaceS',
  );
  @override
  late final GeneratedColumn<double> inversionPaceS = GeneratedColumn<double>(
    'inversion_pace_s',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () => status.isIn(['active', 'completed', 'aborted']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _abortedAtStepMeta = const VerificationMeta(
    'abortedAtStep',
  );
  @override
  late final GeneratedColumn<int> abortedAtStep = GeneratedColumn<int>(
    'aborted_at_step',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stepRunsJsonMeta = const VerificationMeta(
    'stepRunsJson',
  );
  @override
  late final GeneratedColumn<String> stepRunsJson = GeneratedColumn<String>(
    'step_runs_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tankSlot,
    tankLabel,
    keyCanonical,
    keyJson,
    timeSourceJson,
    devTimeS,
    format,
    volumeMl,
    processSnapshotJson,
    inversionPaceS,
    status,
    abortedAtStep,
    startedAt,
    finishedAt,
    stepRunsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tank_slot')) {
      context.handle(
        _tankSlotMeta,
        tankSlot.isAcceptableOrUnknown(data['tank_slot']!, _tankSlotMeta),
      );
    } else if (isInserting) {
      context.missing(_tankSlotMeta);
    }
    if (data.containsKey('tank_label')) {
      context.handle(
        _tankLabelMeta,
        tankLabel.isAcceptableOrUnknown(data['tank_label']!, _tankLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_tankLabelMeta);
    }
    if (data.containsKey('key_canonical')) {
      context.handle(
        _keyCanonicalMeta,
        keyCanonical.isAcceptableOrUnknown(
          data['key_canonical']!,
          _keyCanonicalMeta,
        ),
      );
    }
    if (data.containsKey('key_json')) {
      context.handle(
        _keyJsonMeta,
        keyJson.isAcceptableOrUnknown(data['key_json']!, _keyJsonMeta),
      );
    }
    if (data.containsKey('time_source_json')) {
      context.handle(
        _timeSourceJsonMeta,
        timeSourceJson.isAcceptableOrUnknown(
          data['time_source_json']!,
          _timeSourceJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeSourceJsonMeta);
    }
    if (data.containsKey('dev_time_s')) {
      context.handle(
        _devTimeSMeta,
        devTimeS.isAcceptableOrUnknown(data['dev_time_s']!, _devTimeSMeta),
      );
    } else if (isInserting) {
      context.missing(_devTimeSMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('volume_ml')) {
      context.handle(
        _volumeMlMeta,
        volumeMl.isAcceptableOrUnknown(data['volume_ml']!, _volumeMlMeta),
      );
    } else if (isInserting) {
      context.missing(_volumeMlMeta);
    }
    if (data.containsKey('process_snapshot_json')) {
      context.handle(
        _processSnapshotJsonMeta,
        processSnapshotJson.isAcceptableOrUnknown(
          data['process_snapshot_json']!,
          _processSnapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_processSnapshotJsonMeta);
    }
    if (data.containsKey('inversion_pace_s')) {
      context.handle(
        _inversionPaceSMeta,
        inversionPaceS.isAcceptableOrUnknown(
          data['inversion_pace_s']!,
          _inversionPaceSMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inversionPaceSMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('aborted_at_step')) {
      context.handle(
        _abortedAtStepMeta,
        abortedAtStep.isAcceptableOrUnknown(
          data['aborted_at_step']!,
          _abortedAtStepMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('step_runs_json')) {
      context.handle(
        _stepRunsJsonMeta,
        stepRunsJson.isAcceptableOrUnknown(
          data['step_runs_json']!,
          _stepRunsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stepRunsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tankSlot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tank_slot'],
      )!,
      tankLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tank_label'],
      )!,
      keyCanonical: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_canonical'],
      ),
      keyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_json'],
      ),
      timeSourceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_source_json'],
      )!,
      devTimeS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dev_time_s'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      volumeMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}volume_ml'],
      )!,
      processSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}process_snapshot_json'],
      )!,
      inversionPaceS: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}inversion_pace_s'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      abortedAtStep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}aborted_at_step'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      stepRunsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}step_runs_json'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final int tankSlot;
  final String tankLabel;
  final String? keyCanonical;
  final String? keyJson;
  final String timeSourceJson;
  final int devTimeS;
  final String format;
  final int volumeMl;
  final String processSnapshotJson;
  final double inversionPaceS;
  final String status;
  final int? abortedAtStep;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String stepRunsJson;
  const Session({
    required this.id,
    required this.tankSlot,
    required this.tankLabel,
    this.keyCanonical,
    this.keyJson,
    required this.timeSourceJson,
    required this.devTimeS,
    required this.format,
    required this.volumeMl,
    required this.processSnapshotJson,
    required this.inversionPaceS,
    required this.status,
    this.abortedAtStep,
    required this.startedAt,
    this.finishedAt,
    required this.stepRunsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tank_slot'] = Variable<int>(tankSlot);
    map['tank_label'] = Variable<String>(tankLabel);
    if (!nullToAbsent || keyCanonical != null) {
      map['key_canonical'] = Variable<String>(keyCanonical);
    }
    if (!nullToAbsent || keyJson != null) {
      map['key_json'] = Variable<String>(keyJson);
    }
    map['time_source_json'] = Variable<String>(timeSourceJson);
    map['dev_time_s'] = Variable<int>(devTimeS);
    map['format'] = Variable<String>(format);
    map['volume_ml'] = Variable<int>(volumeMl);
    map['process_snapshot_json'] = Variable<String>(processSnapshotJson);
    map['inversion_pace_s'] = Variable<double>(inversionPaceS);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || abortedAtStep != null) {
      map['aborted_at_step'] = Variable<int>(abortedAtStep);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    map['step_runs_json'] = Variable<String>(stepRunsJson);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      tankSlot: Value(tankSlot),
      tankLabel: Value(tankLabel),
      keyCanonical: keyCanonical == null && nullToAbsent
          ? const Value.absent()
          : Value(keyCanonical),
      keyJson: keyJson == null && nullToAbsent
          ? const Value.absent()
          : Value(keyJson),
      timeSourceJson: Value(timeSourceJson),
      devTimeS: Value(devTimeS),
      format: Value(format),
      volumeMl: Value(volumeMl),
      processSnapshotJson: Value(processSnapshotJson),
      inversionPaceS: Value(inversionPaceS),
      status: Value(status),
      abortedAtStep: abortedAtStep == null && nullToAbsent
          ? const Value.absent()
          : Value(abortedAtStep),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      stepRunsJson: Value(stepRunsJson),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      tankSlot: serializer.fromJson<int>(json['tankSlot']),
      tankLabel: serializer.fromJson<String>(json['tankLabel']),
      keyCanonical: serializer.fromJson<String?>(json['keyCanonical']),
      keyJson: serializer.fromJson<String?>(json['keyJson']),
      timeSourceJson: serializer.fromJson<String>(json['timeSourceJson']),
      devTimeS: serializer.fromJson<int>(json['devTimeS']),
      format: serializer.fromJson<String>(json['format']),
      volumeMl: serializer.fromJson<int>(json['volumeMl']),
      processSnapshotJson: serializer.fromJson<String>(
        json['processSnapshotJson'],
      ),
      inversionPaceS: serializer.fromJson<double>(json['inversionPaceS']),
      status: serializer.fromJson<String>(json['status']),
      abortedAtStep: serializer.fromJson<int?>(json['abortedAtStep']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      stepRunsJson: serializer.fromJson<String>(json['stepRunsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tankSlot': serializer.toJson<int>(tankSlot),
      'tankLabel': serializer.toJson<String>(tankLabel),
      'keyCanonical': serializer.toJson<String?>(keyCanonical),
      'keyJson': serializer.toJson<String?>(keyJson),
      'timeSourceJson': serializer.toJson<String>(timeSourceJson),
      'devTimeS': serializer.toJson<int>(devTimeS),
      'format': serializer.toJson<String>(format),
      'volumeMl': serializer.toJson<int>(volumeMl),
      'processSnapshotJson': serializer.toJson<String>(processSnapshotJson),
      'inversionPaceS': serializer.toJson<double>(inversionPaceS),
      'status': serializer.toJson<String>(status),
      'abortedAtStep': serializer.toJson<int?>(abortedAtStep),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'stepRunsJson': serializer.toJson<String>(stepRunsJson),
    };
  }

  Session copyWith({
    String? id,
    int? tankSlot,
    String? tankLabel,
    Value<String?> keyCanonical = const Value.absent(),
    Value<String?> keyJson = const Value.absent(),
    String? timeSourceJson,
    int? devTimeS,
    String? format,
    int? volumeMl,
    String? processSnapshotJson,
    double? inversionPaceS,
    String? status,
    Value<int?> abortedAtStep = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    String? stepRunsJson,
  }) => Session(
    id: id ?? this.id,
    tankSlot: tankSlot ?? this.tankSlot,
    tankLabel: tankLabel ?? this.tankLabel,
    keyCanonical: keyCanonical.present ? keyCanonical.value : this.keyCanonical,
    keyJson: keyJson.present ? keyJson.value : this.keyJson,
    timeSourceJson: timeSourceJson ?? this.timeSourceJson,
    devTimeS: devTimeS ?? this.devTimeS,
    format: format ?? this.format,
    volumeMl: volumeMl ?? this.volumeMl,
    processSnapshotJson: processSnapshotJson ?? this.processSnapshotJson,
    inversionPaceS: inversionPaceS ?? this.inversionPaceS,
    status: status ?? this.status,
    abortedAtStep: abortedAtStep.present
        ? abortedAtStep.value
        : this.abortedAtStep,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    stepRunsJson: stepRunsJson ?? this.stepRunsJson,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      tankSlot: data.tankSlot.present ? data.tankSlot.value : this.tankSlot,
      tankLabel: data.tankLabel.present ? data.tankLabel.value : this.tankLabel,
      keyCanonical: data.keyCanonical.present
          ? data.keyCanonical.value
          : this.keyCanonical,
      keyJson: data.keyJson.present ? data.keyJson.value : this.keyJson,
      timeSourceJson: data.timeSourceJson.present
          ? data.timeSourceJson.value
          : this.timeSourceJson,
      devTimeS: data.devTimeS.present ? data.devTimeS.value : this.devTimeS,
      format: data.format.present ? data.format.value : this.format,
      volumeMl: data.volumeMl.present ? data.volumeMl.value : this.volumeMl,
      processSnapshotJson: data.processSnapshotJson.present
          ? data.processSnapshotJson.value
          : this.processSnapshotJson,
      inversionPaceS: data.inversionPaceS.present
          ? data.inversionPaceS.value
          : this.inversionPaceS,
      status: data.status.present ? data.status.value : this.status,
      abortedAtStep: data.abortedAtStep.present
          ? data.abortedAtStep.value
          : this.abortedAtStep,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      stepRunsJson: data.stepRunsJson.present
          ? data.stepRunsJson.value
          : this.stepRunsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('tankSlot: $tankSlot, ')
          ..write('tankLabel: $tankLabel, ')
          ..write('keyCanonical: $keyCanonical, ')
          ..write('keyJson: $keyJson, ')
          ..write('timeSourceJson: $timeSourceJson, ')
          ..write('devTimeS: $devTimeS, ')
          ..write('format: $format, ')
          ..write('volumeMl: $volumeMl, ')
          ..write('processSnapshotJson: $processSnapshotJson, ')
          ..write('inversionPaceS: $inversionPaceS, ')
          ..write('status: $status, ')
          ..write('abortedAtStep: $abortedAtStep, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('stepRunsJson: $stepRunsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tankSlot,
    tankLabel,
    keyCanonical,
    keyJson,
    timeSourceJson,
    devTimeS,
    format,
    volumeMl,
    processSnapshotJson,
    inversionPaceS,
    status,
    abortedAtStep,
    startedAt,
    finishedAt,
    stepRunsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.tankSlot == this.tankSlot &&
          other.tankLabel == this.tankLabel &&
          other.keyCanonical == this.keyCanonical &&
          other.keyJson == this.keyJson &&
          other.timeSourceJson == this.timeSourceJson &&
          other.devTimeS == this.devTimeS &&
          other.format == this.format &&
          other.volumeMl == this.volumeMl &&
          other.processSnapshotJson == this.processSnapshotJson &&
          other.inversionPaceS == this.inversionPaceS &&
          other.status == this.status &&
          other.abortedAtStep == this.abortedAtStep &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.stepRunsJson == this.stepRunsJson);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<int> tankSlot;
  final Value<String> tankLabel;
  final Value<String?> keyCanonical;
  final Value<String?> keyJson;
  final Value<String> timeSourceJson;
  final Value<int> devTimeS;
  final Value<String> format;
  final Value<int> volumeMl;
  final Value<String> processSnapshotJson;
  final Value<double> inversionPaceS;
  final Value<String> status;
  final Value<int?> abortedAtStep;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<String> stepRunsJson;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.tankSlot = const Value.absent(),
    this.tankLabel = const Value.absent(),
    this.keyCanonical = const Value.absent(),
    this.keyJson = const Value.absent(),
    this.timeSourceJson = const Value.absent(),
    this.devTimeS = const Value.absent(),
    this.format = const Value.absent(),
    this.volumeMl = const Value.absent(),
    this.processSnapshotJson = const Value.absent(),
    this.inversionPaceS = const Value.absent(),
    this.status = const Value.absent(),
    this.abortedAtStep = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.stepRunsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required int tankSlot,
    required String tankLabel,
    this.keyCanonical = const Value.absent(),
    this.keyJson = const Value.absent(),
    required String timeSourceJson,
    required int devTimeS,
    required String format,
    required int volumeMl,
    required String processSnapshotJson,
    required double inversionPaceS,
    required String status,
    this.abortedAtStep = const Value.absent(),
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    required String stepRunsJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tankSlot = Value(tankSlot),
       tankLabel = Value(tankLabel),
       timeSourceJson = Value(timeSourceJson),
       devTimeS = Value(devTimeS),
       format = Value(format),
       volumeMl = Value(volumeMl),
       processSnapshotJson = Value(processSnapshotJson),
       inversionPaceS = Value(inversionPaceS),
       status = Value(status),
       startedAt = Value(startedAt),
       stepRunsJson = Value(stepRunsJson);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<int>? tankSlot,
    Expression<String>? tankLabel,
    Expression<String>? keyCanonical,
    Expression<String>? keyJson,
    Expression<String>? timeSourceJson,
    Expression<int>? devTimeS,
    Expression<String>? format,
    Expression<int>? volumeMl,
    Expression<String>? processSnapshotJson,
    Expression<double>? inversionPaceS,
    Expression<String>? status,
    Expression<int>? abortedAtStep,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<String>? stepRunsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tankSlot != null) 'tank_slot': tankSlot,
      if (tankLabel != null) 'tank_label': tankLabel,
      if (keyCanonical != null) 'key_canonical': keyCanonical,
      if (keyJson != null) 'key_json': keyJson,
      if (timeSourceJson != null) 'time_source_json': timeSourceJson,
      if (devTimeS != null) 'dev_time_s': devTimeS,
      if (format != null) 'format': format,
      if (volumeMl != null) 'volume_ml': volumeMl,
      if (processSnapshotJson != null)
        'process_snapshot_json': processSnapshotJson,
      if (inversionPaceS != null) 'inversion_pace_s': inversionPaceS,
      if (status != null) 'status': status,
      if (abortedAtStep != null) 'aborted_at_step': abortedAtStep,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (stepRunsJson != null) 'step_runs_json': stepRunsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<int>? tankSlot,
    Value<String>? tankLabel,
    Value<String?>? keyCanonical,
    Value<String?>? keyJson,
    Value<String>? timeSourceJson,
    Value<int>? devTimeS,
    Value<String>? format,
    Value<int>? volumeMl,
    Value<String>? processSnapshotJson,
    Value<double>? inversionPaceS,
    Value<String>? status,
    Value<int?>? abortedAtStep,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<String>? stepRunsJson,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      tankSlot: tankSlot ?? this.tankSlot,
      tankLabel: tankLabel ?? this.tankLabel,
      keyCanonical: keyCanonical ?? this.keyCanonical,
      keyJson: keyJson ?? this.keyJson,
      timeSourceJson: timeSourceJson ?? this.timeSourceJson,
      devTimeS: devTimeS ?? this.devTimeS,
      format: format ?? this.format,
      volumeMl: volumeMl ?? this.volumeMl,
      processSnapshotJson: processSnapshotJson ?? this.processSnapshotJson,
      inversionPaceS: inversionPaceS ?? this.inversionPaceS,
      status: status ?? this.status,
      abortedAtStep: abortedAtStep ?? this.abortedAtStep,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      stepRunsJson: stepRunsJson ?? this.stepRunsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tankSlot.present) {
      map['tank_slot'] = Variable<int>(tankSlot.value);
    }
    if (tankLabel.present) {
      map['tank_label'] = Variable<String>(tankLabel.value);
    }
    if (keyCanonical.present) {
      map['key_canonical'] = Variable<String>(keyCanonical.value);
    }
    if (keyJson.present) {
      map['key_json'] = Variable<String>(keyJson.value);
    }
    if (timeSourceJson.present) {
      map['time_source_json'] = Variable<String>(timeSourceJson.value);
    }
    if (devTimeS.present) {
      map['dev_time_s'] = Variable<int>(devTimeS.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (volumeMl.present) {
      map['volume_ml'] = Variable<int>(volumeMl.value);
    }
    if (processSnapshotJson.present) {
      map['process_snapshot_json'] = Variable<String>(
        processSnapshotJson.value,
      );
    }
    if (inversionPaceS.present) {
      map['inversion_pace_s'] = Variable<double>(inversionPaceS.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (abortedAtStep.present) {
      map['aborted_at_step'] = Variable<int>(abortedAtStep.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (stepRunsJson.present) {
      map['step_runs_json'] = Variable<String>(stepRunsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('tankSlot: $tankSlot, ')
          ..write('tankLabel: $tankLabel, ')
          ..write('keyCanonical: $keyCanonical, ')
          ..write('keyJson: $keyJson, ')
          ..write('timeSourceJson: $timeSourceJson, ')
          ..write('devTimeS: $devTimeS, ')
          ..write('format: $format, ')
          ..write('volumeMl: $volumeMl, ')
          ..write('processSnapshotJson: $processSnapshotJson, ')
          ..write('inversionPaceS: $inversionPaceS, ')
          ..write('status: $status, ')
          ..write('abortedAtStep: $abortedAtStep, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('stepRunsJson: $stepRunsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavouritesTable extends Favourites
    with TableInfo<$FavouritesTable, Favourite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavouritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyCanonicalMeta = const VerificationMeta(
    'keyCanonical',
  );
  @override
  late final GeneratedColumn<String> keyCanonical = GeneratedColumn<String>(
    'key_canonical',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyJsonMeta = const VerificationMeta(
    'keyJson',
  );
  @override
  late final GeneratedColumn<String> keyJson = GeneratedColumn<String>(
    'key_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [keyCanonical, keyJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favourites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favourite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key_canonical')) {
      context.handle(
        _keyCanonicalMeta,
        keyCanonical.isAcceptableOrUnknown(
          data['key_canonical']!,
          _keyCanonicalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keyCanonicalMeta);
    }
    if (data.containsKey('key_json')) {
      context.handle(
        _keyJsonMeta,
        keyJson.isAcceptableOrUnknown(data['key_json']!, _keyJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_keyJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {keyCanonical};
  @override
  Favourite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favourite(
      keyCanonical: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_canonical'],
      )!,
      keyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavouritesTable createAlias(String alias) {
    return $FavouritesTable(attachedDatabase, alias);
  }
}

class Favourite extends DataClass implements Insertable<Favourite> {
  final String keyCanonical;
  final String keyJson;
  final DateTime createdAt;
  const Favourite({
    required this.keyCanonical,
    required this.keyJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key_canonical'] = Variable<String>(keyCanonical);
    map['key_json'] = Variable<String>(keyJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavouritesCompanion toCompanion(bool nullToAbsent) {
    return FavouritesCompanion(
      keyCanonical: Value(keyCanonical),
      keyJson: Value(keyJson),
      createdAt: Value(createdAt),
    );
  }

  factory Favourite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favourite(
      keyCanonical: serializer.fromJson<String>(json['keyCanonical']),
      keyJson: serializer.fromJson<String>(json['keyJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'keyCanonical': serializer.toJson<String>(keyCanonical),
      'keyJson': serializer.toJson<String>(keyJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Favourite copyWith({
    String? keyCanonical,
    String? keyJson,
    DateTime? createdAt,
  }) => Favourite(
    keyCanonical: keyCanonical ?? this.keyCanonical,
    keyJson: keyJson ?? this.keyJson,
    createdAt: createdAt ?? this.createdAt,
  );
  Favourite copyWithCompanion(FavouritesCompanion data) {
    return Favourite(
      keyCanonical: data.keyCanonical.present
          ? data.keyCanonical.value
          : this.keyCanonical,
      keyJson: data.keyJson.present ? data.keyJson.value : this.keyJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favourite(')
          ..write('keyCanonical: $keyCanonical, ')
          ..write('keyJson: $keyJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(keyCanonical, keyJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favourite &&
          other.keyCanonical == this.keyCanonical &&
          other.keyJson == this.keyJson &&
          other.createdAt == this.createdAt);
}

class FavouritesCompanion extends UpdateCompanion<Favourite> {
  final Value<String> keyCanonical;
  final Value<String> keyJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FavouritesCompanion({
    this.keyCanonical = const Value.absent(),
    this.keyJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavouritesCompanion.insert({
    required String keyCanonical,
    required String keyJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : keyCanonical = Value(keyCanonical),
       keyJson = Value(keyJson),
       createdAt = Value(createdAt);
  static Insertable<Favourite> custom({
    Expression<String>? keyCanonical,
    Expression<String>? keyJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (keyCanonical != null) 'key_canonical': keyCanonical,
      if (keyJson != null) 'key_json': keyJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavouritesCompanion copyWith({
    Value<String>? keyCanonical,
    Value<String>? keyJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FavouritesCompanion(
      keyCanonical: keyCanonical ?? this.keyCanonical,
      keyJson: keyJson ?? this.keyJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (keyCanonical.present) {
      map['key_canonical'] = Variable<String>(keyCanonical.value);
    }
    if (keyJson.present) {
      map['key_json'] = Variable<String>(keyJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavouritesCompanion(')
          ..write('keyCanonical: $keyCanonical, ')
          ..write('keyJson: $keyJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsRowsTable extends SettingsRows
    with TableInfo<$SettingsRowsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _authorNameMeta = const VerificationMeta(
    'authorName',
  );
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
    'author_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _volume35mmMlMeta = const VerificationMeta(
    'volume35mmMl',
  );
  @override
  late final GeneratedColumn<int> volume35mmMl = GeneratedColumn<int>(
    'volume35mm_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(300),
  );
  static const VerificationMeta _volume120MlMeta = const VerificationMeta(
    'volume120Ml',
  );
  @override
  late final GeneratedColumn<int> volume120Ml = GeneratedColumn<int>(
    'volume120_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(500),
  );
  static const VerificationMeta _defaultProcessIdMeta = const VerificationMeta(
    'defaultProcessId',
  );
  @override
  late final GeneratedColumn<String> defaultProcessId = GeneratedColumn<String>(
    'default_process_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
  );
  static const VerificationMeta _inversionPaceSMeta = const VerificationMeta(
    'inversionPaceS',
  );
  @override
  late final GeneratedColumn<double> inversionPaceS = GeneratedColumn<double>(
    'inversion_pace_s',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.0),
  );
  static const VerificationMeta _soundOnMeta = const VerificationMeta(
    'soundOn',
  );
  @override
  late final GeneratedColumn<bool> soundOn = GeneratedColumn<bool>(
    'sound_on',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sound_on" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _volumeMeta = const VerificationMeta('volume');
  @override
  late final GeneratedColumn<double> volume = GeneratedColumn<double>(
    'volume',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.7),
  );
  static const VerificationMeta _volumeKeyNextMeta = const VerificationMeta(
    'volumeKeyNext',
  );
  @override
  late final GeneratedColumn<bool> volumeKeyNext = GeneratedColumn<bool>(
    'volume_key_next',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("volume_key_next" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _tempUnitMeta = const VerificationMeta(
    'tempUnit',
  );
  @override
  late final GeneratedColumn<String> tempUnit = GeneratedColumn<String>(
    'temp_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('c'),
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _lastModeMeta = const VerificationMeta(
    'lastMode',
  );
  @override
  late final GeneratedColumn<String> lastMode = GeneratedColumn<String>(
    'last_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('develop'),
  );
  static const VerificationMeta _backgroundLimitSeenMeta =
      const VerificationMeta('backgroundLimitSeen');
  @override
  late final GeneratedColumn<bool> backgroundLimitSeen = GeneratedColumn<bool>(
    'background_limit_seen',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("background_limit_seen" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notificationsAskedMeta =
      const VerificationMeta('notificationsAsked');
  @override
  late final GeneratedColumn<bool> notificationsAsked = GeneratedColumn<bool>(
    'notifications_asked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications_asked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastFormatMeta = const VerificationMeta(
    'lastFormat',
  );
  @override
  late final GeneratedColumn<String> lastFormat = GeneratedColumn<String>(
    'last_format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('35mm'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    authorName,
    volume35mmMl,
    volume120Ml,
    defaultProcessId,
    inversionPaceS,
    soundOn,
    volume,
    volumeKeyNext,
    tempUnit,
    theme,
    lastMode,
    backgroundLimitSeen,
    notificationsAsked,
    lastFormat,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('author_name')) {
      context.handle(
        _authorNameMeta,
        authorName.isAcceptableOrUnknown(data['author_name']!, _authorNameMeta),
      );
    }
    if (data.containsKey('volume35mm_ml')) {
      context.handle(
        _volume35mmMlMeta,
        volume35mmMl.isAcceptableOrUnknown(
          data['volume35mm_ml']!,
          _volume35mmMlMeta,
        ),
      );
    }
    if (data.containsKey('volume120_ml')) {
      context.handle(
        _volume120MlMeta,
        volume120Ml.isAcceptableOrUnknown(
          data['volume120_ml']!,
          _volume120MlMeta,
        ),
      );
    }
    if (data.containsKey('default_process_id')) {
      context.handle(
        _defaultProcessIdMeta,
        defaultProcessId.isAcceptableOrUnknown(
          data['default_process_id']!,
          _defaultProcessIdMeta,
        ),
      );
    }
    if (data.containsKey('inversion_pace_s')) {
      context.handle(
        _inversionPaceSMeta,
        inversionPaceS.isAcceptableOrUnknown(
          data['inversion_pace_s']!,
          _inversionPaceSMeta,
        ),
      );
    }
    if (data.containsKey('sound_on')) {
      context.handle(
        _soundOnMeta,
        soundOn.isAcceptableOrUnknown(data['sound_on']!, _soundOnMeta),
      );
    }
    if (data.containsKey('volume')) {
      context.handle(
        _volumeMeta,
        volume.isAcceptableOrUnknown(data['volume']!, _volumeMeta),
      );
    }
    if (data.containsKey('volume_key_next')) {
      context.handle(
        _volumeKeyNextMeta,
        volumeKeyNext.isAcceptableOrUnknown(
          data['volume_key_next']!,
          _volumeKeyNextMeta,
        ),
      );
    }
    if (data.containsKey('temp_unit')) {
      context.handle(
        _tempUnitMeta,
        tempUnit.isAcceptableOrUnknown(data['temp_unit']!, _tempUnitMeta),
      );
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    }
    if (data.containsKey('last_mode')) {
      context.handle(
        _lastModeMeta,
        lastMode.isAcceptableOrUnknown(data['last_mode']!, _lastModeMeta),
      );
    }
    if (data.containsKey('background_limit_seen')) {
      context.handle(
        _backgroundLimitSeenMeta,
        backgroundLimitSeen.isAcceptableOrUnknown(
          data['background_limit_seen']!,
          _backgroundLimitSeenMeta,
        ),
      );
    }
    if (data.containsKey('notifications_asked')) {
      context.handle(
        _notificationsAskedMeta,
        notificationsAsked.isAcceptableOrUnknown(
          data['notifications_asked']!,
          _notificationsAskedMeta,
        ),
      );
    }
    if (data.containsKey('last_format')) {
      context.handle(
        _lastFormatMeta,
        lastFormat.isAcceptableOrUnknown(data['last_format']!, _lastFormatMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      authorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_name'],
      )!,
      volume35mmMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}volume35mm_ml'],
      )!,
      volume120Ml: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}volume120_ml'],
      )!,
      defaultProcessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_process_id'],
      )!,
      inversionPaceS: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}inversion_pace_s'],
      )!,
      soundOn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sound_on'],
      )!,
      volume: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}volume'],
      )!,
      volumeKeyNext: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}volume_key_next'],
      )!,
      tempUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}temp_unit'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
      lastMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_mode'],
      )!,
      backgroundLimitSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}background_limit_seen'],
      )!,
      notificationsAsked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications_asked'],
      )!,
      lastFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_format'],
      )!,
    );
  }

  @override
  $SettingsRowsTable createAlias(String alias) {
    return $SettingsRowsTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final String authorName;
  final int volume35mmMl;
  final int volume120Ml;
  final String defaultProcessId;
  final double inversionPaceS;
  final bool soundOn;
  final double volume;
  final bool volumeKeyNext;
  final String tempUnit;
  final String theme;
  final String lastMode;
  final bool backgroundLimitSeen;
  final bool notificationsAsked;
  final String lastFormat;
  const SettingsRow({
    required this.id,
    required this.authorName,
    required this.volume35mmMl,
    required this.volume120Ml,
    required this.defaultProcessId,
    required this.inversionPaceS,
    required this.soundOn,
    required this.volume,
    required this.volumeKeyNext,
    required this.tempUnit,
    required this.theme,
    required this.lastMode,
    required this.backgroundLimitSeen,
    required this.notificationsAsked,
    required this.lastFormat,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['author_name'] = Variable<String>(authorName);
    map['volume35mm_ml'] = Variable<int>(volume35mmMl);
    map['volume120_ml'] = Variable<int>(volume120Ml);
    map['default_process_id'] = Variable<String>(defaultProcessId);
    map['inversion_pace_s'] = Variable<double>(inversionPaceS);
    map['sound_on'] = Variable<bool>(soundOn);
    map['volume'] = Variable<double>(volume);
    map['volume_key_next'] = Variable<bool>(volumeKeyNext);
    map['temp_unit'] = Variable<String>(tempUnit);
    map['theme'] = Variable<String>(theme);
    map['last_mode'] = Variable<String>(lastMode);
    map['background_limit_seen'] = Variable<bool>(backgroundLimitSeen);
    map['notifications_asked'] = Variable<bool>(notificationsAsked);
    map['last_format'] = Variable<String>(lastFormat);
    return map;
  }

  SettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingsRowsCompanion(
      id: Value(id),
      authorName: Value(authorName),
      volume35mmMl: Value(volume35mmMl),
      volume120Ml: Value(volume120Ml),
      defaultProcessId: Value(defaultProcessId),
      inversionPaceS: Value(inversionPaceS),
      soundOn: Value(soundOn),
      volume: Value(volume),
      volumeKeyNext: Value(volumeKeyNext),
      tempUnit: Value(tempUnit),
      theme: Value(theme),
      lastMode: Value(lastMode),
      backgroundLimitSeen: Value(backgroundLimitSeen),
      notificationsAsked: Value(notificationsAsked),
      lastFormat: Value(lastFormat),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      authorName: serializer.fromJson<String>(json['authorName']),
      volume35mmMl: serializer.fromJson<int>(json['volume35mmMl']),
      volume120Ml: serializer.fromJson<int>(json['volume120Ml']),
      defaultProcessId: serializer.fromJson<String>(json['defaultProcessId']),
      inversionPaceS: serializer.fromJson<double>(json['inversionPaceS']),
      soundOn: serializer.fromJson<bool>(json['soundOn']),
      volume: serializer.fromJson<double>(json['volume']),
      volumeKeyNext: serializer.fromJson<bool>(json['volumeKeyNext']),
      tempUnit: serializer.fromJson<String>(json['tempUnit']),
      theme: serializer.fromJson<String>(json['theme']),
      lastMode: serializer.fromJson<String>(json['lastMode']),
      backgroundLimitSeen: serializer.fromJson<bool>(
        json['backgroundLimitSeen'],
      ),
      notificationsAsked: serializer.fromJson<bool>(json['notificationsAsked']),
      lastFormat: serializer.fromJson<String>(json['lastFormat']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'authorName': serializer.toJson<String>(authorName),
      'volume35mmMl': serializer.toJson<int>(volume35mmMl),
      'volume120Ml': serializer.toJson<int>(volume120Ml),
      'defaultProcessId': serializer.toJson<String>(defaultProcessId),
      'inversionPaceS': serializer.toJson<double>(inversionPaceS),
      'soundOn': serializer.toJson<bool>(soundOn),
      'volume': serializer.toJson<double>(volume),
      'volumeKeyNext': serializer.toJson<bool>(volumeKeyNext),
      'tempUnit': serializer.toJson<String>(tempUnit),
      'theme': serializer.toJson<String>(theme),
      'lastMode': serializer.toJson<String>(lastMode),
      'backgroundLimitSeen': serializer.toJson<bool>(backgroundLimitSeen),
      'notificationsAsked': serializer.toJson<bool>(notificationsAsked),
      'lastFormat': serializer.toJson<String>(lastFormat),
    };
  }

  SettingsRow copyWith({
    int? id,
    String? authorName,
    int? volume35mmMl,
    int? volume120Ml,
    String? defaultProcessId,
    double? inversionPaceS,
    bool? soundOn,
    double? volume,
    bool? volumeKeyNext,
    String? tempUnit,
    String? theme,
    String? lastMode,
    bool? backgroundLimitSeen,
    bool? notificationsAsked,
    String? lastFormat,
  }) => SettingsRow(
    id: id ?? this.id,
    authorName: authorName ?? this.authorName,
    volume35mmMl: volume35mmMl ?? this.volume35mmMl,
    volume120Ml: volume120Ml ?? this.volume120Ml,
    defaultProcessId: defaultProcessId ?? this.defaultProcessId,
    inversionPaceS: inversionPaceS ?? this.inversionPaceS,
    soundOn: soundOn ?? this.soundOn,
    volume: volume ?? this.volume,
    volumeKeyNext: volumeKeyNext ?? this.volumeKeyNext,
    tempUnit: tempUnit ?? this.tempUnit,
    theme: theme ?? this.theme,
    lastMode: lastMode ?? this.lastMode,
    backgroundLimitSeen: backgroundLimitSeen ?? this.backgroundLimitSeen,
    notificationsAsked: notificationsAsked ?? this.notificationsAsked,
    lastFormat: lastFormat ?? this.lastFormat,
  );
  SettingsRow copyWithCompanion(SettingsRowsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      authorName: data.authorName.present
          ? data.authorName.value
          : this.authorName,
      volume35mmMl: data.volume35mmMl.present
          ? data.volume35mmMl.value
          : this.volume35mmMl,
      volume120Ml: data.volume120Ml.present
          ? data.volume120Ml.value
          : this.volume120Ml,
      defaultProcessId: data.defaultProcessId.present
          ? data.defaultProcessId.value
          : this.defaultProcessId,
      inversionPaceS: data.inversionPaceS.present
          ? data.inversionPaceS.value
          : this.inversionPaceS,
      soundOn: data.soundOn.present ? data.soundOn.value : this.soundOn,
      volume: data.volume.present ? data.volume.value : this.volume,
      volumeKeyNext: data.volumeKeyNext.present
          ? data.volumeKeyNext.value
          : this.volumeKeyNext,
      tempUnit: data.tempUnit.present ? data.tempUnit.value : this.tempUnit,
      theme: data.theme.present ? data.theme.value : this.theme,
      lastMode: data.lastMode.present ? data.lastMode.value : this.lastMode,
      backgroundLimitSeen: data.backgroundLimitSeen.present
          ? data.backgroundLimitSeen.value
          : this.backgroundLimitSeen,
      notificationsAsked: data.notificationsAsked.present
          ? data.notificationsAsked.value
          : this.notificationsAsked,
      lastFormat: data.lastFormat.present
          ? data.lastFormat.value
          : this.lastFormat,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('authorName: $authorName, ')
          ..write('volume35mmMl: $volume35mmMl, ')
          ..write('volume120Ml: $volume120Ml, ')
          ..write('defaultProcessId: $defaultProcessId, ')
          ..write('inversionPaceS: $inversionPaceS, ')
          ..write('soundOn: $soundOn, ')
          ..write('volume: $volume, ')
          ..write('volumeKeyNext: $volumeKeyNext, ')
          ..write('tempUnit: $tempUnit, ')
          ..write('theme: $theme, ')
          ..write('lastMode: $lastMode, ')
          ..write('backgroundLimitSeen: $backgroundLimitSeen, ')
          ..write('notificationsAsked: $notificationsAsked, ')
          ..write('lastFormat: $lastFormat')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    authorName,
    volume35mmMl,
    volume120Ml,
    defaultProcessId,
    inversionPaceS,
    soundOn,
    volume,
    volumeKeyNext,
    tempUnit,
    theme,
    lastMode,
    backgroundLimitSeen,
    notificationsAsked,
    lastFormat,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.authorName == this.authorName &&
          other.volume35mmMl == this.volume35mmMl &&
          other.volume120Ml == this.volume120Ml &&
          other.defaultProcessId == this.defaultProcessId &&
          other.inversionPaceS == this.inversionPaceS &&
          other.soundOn == this.soundOn &&
          other.volume == this.volume &&
          other.volumeKeyNext == this.volumeKeyNext &&
          other.tempUnit == this.tempUnit &&
          other.theme == this.theme &&
          other.lastMode == this.lastMode &&
          other.backgroundLimitSeen == this.backgroundLimitSeen &&
          other.notificationsAsked == this.notificationsAsked &&
          other.lastFormat == this.lastFormat);
}

class SettingsRowsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String> authorName;
  final Value<int> volume35mmMl;
  final Value<int> volume120Ml;
  final Value<String> defaultProcessId;
  final Value<double> inversionPaceS;
  final Value<bool> soundOn;
  final Value<double> volume;
  final Value<bool> volumeKeyNext;
  final Value<String> tempUnit;
  final Value<String> theme;
  final Value<String> lastMode;
  final Value<bool> backgroundLimitSeen;
  final Value<bool> notificationsAsked;
  final Value<String> lastFormat;
  const SettingsRowsCompanion({
    this.id = const Value.absent(),
    this.authorName = const Value.absent(),
    this.volume35mmMl = const Value.absent(),
    this.volume120Ml = const Value.absent(),
    this.defaultProcessId = const Value.absent(),
    this.inversionPaceS = const Value.absent(),
    this.soundOn = const Value.absent(),
    this.volume = const Value.absent(),
    this.volumeKeyNext = const Value.absent(),
    this.tempUnit = const Value.absent(),
    this.theme = const Value.absent(),
    this.lastMode = const Value.absent(),
    this.backgroundLimitSeen = const Value.absent(),
    this.notificationsAsked = const Value.absent(),
    this.lastFormat = const Value.absent(),
  });
  SettingsRowsCompanion.insert({
    this.id = const Value.absent(),
    this.authorName = const Value.absent(),
    this.volume35mmMl = const Value.absent(),
    this.volume120Ml = const Value.absent(),
    this.defaultProcessId = const Value.absent(),
    this.inversionPaceS = const Value.absent(),
    this.soundOn = const Value.absent(),
    this.volume = const Value.absent(),
    this.volumeKeyNext = const Value.absent(),
    this.tempUnit = const Value.absent(),
    this.theme = const Value.absent(),
    this.lastMode = const Value.absent(),
    this.backgroundLimitSeen = const Value.absent(),
    this.notificationsAsked = const Value.absent(),
    this.lastFormat = const Value.absent(),
  });
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? authorName,
    Expression<int>? volume35mmMl,
    Expression<int>? volume120Ml,
    Expression<String>? defaultProcessId,
    Expression<double>? inversionPaceS,
    Expression<bool>? soundOn,
    Expression<double>? volume,
    Expression<bool>? volumeKeyNext,
    Expression<String>? tempUnit,
    Expression<String>? theme,
    Expression<String>? lastMode,
    Expression<bool>? backgroundLimitSeen,
    Expression<bool>? notificationsAsked,
    Expression<String>? lastFormat,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (authorName != null) 'author_name': authorName,
      if (volume35mmMl != null) 'volume35mm_ml': volume35mmMl,
      if (volume120Ml != null) 'volume120_ml': volume120Ml,
      if (defaultProcessId != null) 'default_process_id': defaultProcessId,
      if (inversionPaceS != null) 'inversion_pace_s': inversionPaceS,
      if (soundOn != null) 'sound_on': soundOn,
      if (volume != null) 'volume': volume,
      if (volumeKeyNext != null) 'volume_key_next': volumeKeyNext,
      if (tempUnit != null) 'temp_unit': tempUnit,
      if (theme != null) 'theme': theme,
      if (lastMode != null) 'last_mode': lastMode,
      if (backgroundLimitSeen != null)
        'background_limit_seen': backgroundLimitSeen,
      if (notificationsAsked != null) 'notifications_asked': notificationsAsked,
      if (lastFormat != null) 'last_format': lastFormat,
    });
  }

  SettingsRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? authorName,
    Value<int>? volume35mmMl,
    Value<int>? volume120Ml,
    Value<String>? defaultProcessId,
    Value<double>? inversionPaceS,
    Value<bool>? soundOn,
    Value<double>? volume,
    Value<bool>? volumeKeyNext,
    Value<String>? tempUnit,
    Value<String>? theme,
    Value<String>? lastMode,
    Value<bool>? backgroundLimitSeen,
    Value<bool>? notificationsAsked,
    Value<String>? lastFormat,
  }) {
    return SettingsRowsCompanion(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      volume35mmMl: volume35mmMl ?? this.volume35mmMl,
      volume120Ml: volume120Ml ?? this.volume120Ml,
      defaultProcessId: defaultProcessId ?? this.defaultProcessId,
      inversionPaceS: inversionPaceS ?? this.inversionPaceS,
      soundOn: soundOn ?? this.soundOn,
      volume: volume ?? this.volume,
      volumeKeyNext: volumeKeyNext ?? this.volumeKeyNext,
      tempUnit: tempUnit ?? this.tempUnit,
      theme: theme ?? this.theme,
      lastMode: lastMode ?? this.lastMode,
      backgroundLimitSeen: backgroundLimitSeen ?? this.backgroundLimitSeen,
      notificationsAsked: notificationsAsked ?? this.notificationsAsked,
      lastFormat: lastFormat ?? this.lastFormat,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (volume35mmMl.present) {
      map['volume35mm_ml'] = Variable<int>(volume35mmMl.value);
    }
    if (volume120Ml.present) {
      map['volume120_ml'] = Variable<int>(volume120Ml.value);
    }
    if (defaultProcessId.present) {
      map['default_process_id'] = Variable<String>(defaultProcessId.value);
    }
    if (inversionPaceS.present) {
      map['inversion_pace_s'] = Variable<double>(inversionPaceS.value);
    }
    if (soundOn.present) {
      map['sound_on'] = Variable<bool>(soundOn.value);
    }
    if (volume.present) {
      map['volume'] = Variable<double>(volume.value);
    }
    if (volumeKeyNext.present) {
      map['volume_key_next'] = Variable<bool>(volumeKeyNext.value);
    }
    if (tempUnit.present) {
      map['temp_unit'] = Variable<String>(tempUnit.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (lastMode.present) {
      map['last_mode'] = Variable<String>(lastMode.value);
    }
    if (backgroundLimitSeen.present) {
      map['background_limit_seen'] = Variable<bool>(backgroundLimitSeen.value);
    }
    if (notificationsAsked.present) {
      map['notifications_asked'] = Variable<bool>(notificationsAsked.value);
    }
    if (lastFormat.present) {
      map['last_format'] = Variable<String>(lastFormat.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRowsCompanion(')
          ..write('id: $id, ')
          ..write('authorName: $authorName, ')
          ..write('volume35mmMl: $volume35mmMl, ')
          ..write('volume120Ml: $volume120Ml, ')
          ..write('defaultProcessId: $defaultProcessId, ')
          ..write('inversionPaceS: $inversionPaceS, ')
          ..write('soundOn: $soundOn, ')
          ..write('volume: $volume, ')
          ..write('volumeKeyNext: $volumeKeyNext, ')
          ..write('tempUnit: $tempUnit, ')
          ..write('theme: $theme, ')
          ..write('lastMode: $lastMode, ')
          ..write('backgroundLimitSeen: $backgroundLimitSeen, ')
          ..write('notificationsAsked: $notificationsAsked, ')
          ..write('lastFormat: $lastFormat')
          ..write(')'))
        .toString();
  }
}

class $DatasetStatesTable extends DatasetStates
    with TableInfo<$DatasetStatesTable, DatasetState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatasetStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _activeVersionMeta = const VerificationMeta(
    'activeVersion',
  );
  @override
  late final GeneratedColumn<String> activeVersion = GeneratedColumn<String>(
    'active_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeSha256Meta = const VerificationMeta(
    'activeSha256',
  );
  @override
  late final GeneratedColumn<String> activeSha256 = GeneratedColumn<String>(
    'active_sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    check: () => source.isIn(['bundled', 'downloaded']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastCheckedAtMeta = const VerificationMeta(
    'lastCheckedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastCheckedAt =
      GeneratedColumn<DateTime>(
        'last_checked_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activeVersion,
    activeSha256,
    source,
    lastCheckedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dataset_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<DatasetState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('active_version')) {
      context.handle(
        _activeVersionMeta,
        activeVersion.isAcceptableOrUnknown(
          data['active_version']!,
          _activeVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activeVersionMeta);
    }
    if (data.containsKey('active_sha256')) {
      context.handle(
        _activeSha256Meta,
        activeSha256.isAcceptableOrUnknown(
          data['active_sha256']!,
          _activeSha256Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activeSha256Meta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('last_checked_at')) {
      context.handle(
        _lastCheckedAtMeta,
        lastCheckedAt.isAcceptableOrUnknown(
          data['last_checked_at']!,
          _lastCheckedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DatasetState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DatasetState(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      activeVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_version'],
      )!,
      activeSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_sha256'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      lastCheckedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_checked_at'],
      ),
    );
  }

  @override
  $DatasetStatesTable createAlias(String alias) {
    return $DatasetStatesTable(attachedDatabase, alias);
  }
}

class DatasetState extends DataClass implements Insertable<DatasetState> {
  final int id;
  final String activeVersion;
  final String activeSha256;
  final String source;
  final DateTime? lastCheckedAt;
  const DatasetState({
    required this.id,
    required this.activeVersion,
    required this.activeSha256,
    required this.source,
    this.lastCheckedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['active_version'] = Variable<String>(activeVersion);
    map['active_sha256'] = Variable<String>(activeSha256);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || lastCheckedAt != null) {
      map['last_checked_at'] = Variable<DateTime>(lastCheckedAt);
    }
    return map;
  }

  DatasetStatesCompanion toCompanion(bool nullToAbsent) {
    return DatasetStatesCompanion(
      id: Value(id),
      activeVersion: Value(activeVersion),
      activeSha256: Value(activeSha256),
      source: Value(source),
      lastCheckedAt: lastCheckedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckedAt),
    );
  }

  factory DatasetState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DatasetState(
      id: serializer.fromJson<int>(json['id']),
      activeVersion: serializer.fromJson<String>(json['activeVersion']),
      activeSha256: serializer.fromJson<String>(json['activeSha256']),
      source: serializer.fromJson<String>(json['source']),
      lastCheckedAt: serializer.fromJson<DateTime?>(json['lastCheckedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activeVersion': serializer.toJson<String>(activeVersion),
      'activeSha256': serializer.toJson<String>(activeSha256),
      'source': serializer.toJson<String>(source),
      'lastCheckedAt': serializer.toJson<DateTime?>(lastCheckedAt),
    };
  }

  DatasetState copyWith({
    int? id,
    String? activeVersion,
    String? activeSha256,
    String? source,
    Value<DateTime?> lastCheckedAt = const Value.absent(),
  }) => DatasetState(
    id: id ?? this.id,
    activeVersion: activeVersion ?? this.activeVersion,
    activeSha256: activeSha256 ?? this.activeSha256,
    source: source ?? this.source,
    lastCheckedAt: lastCheckedAt.present
        ? lastCheckedAt.value
        : this.lastCheckedAt,
  );
  DatasetState copyWithCompanion(DatasetStatesCompanion data) {
    return DatasetState(
      id: data.id.present ? data.id.value : this.id,
      activeVersion: data.activeVersion.present
          ? data.activeVersion.value
          : this.activeVersion,
      activeSha256: data.activeSha256.present
          ? data.activeSha256.value
          : this.activeSha256,
      source: data.source.present ? data.source.value : this.source,
      lastCheckedAt: data.lastCheckedAt.present
          ? data.lastCheckedAt.value
          : this.lastCheckedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DatasetState(')
          ..write('id: $id, ')
          ..write('activeVersion: $activeVersion, ')
          ..write('activeSha256: $activeSha256, ')
          ..write('source: $source, ')
          ..write('lastCheckedAt: $lastCheckedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, activeVersion, activeSha256, source, lastCheckedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DatasetState &&
          other.id == this.id &&
          other.activeVersion == this.activeVersion &&
          other.activeSha256 == this.activeSha256 &&
          other.source == this.source &&
          other.lastCheckedAt == this.lastCheckedAt);
}

class DatasetStatesCompanion extends UpdateCompanion<DatasetState> {
  final Value<int> id;
  final Value<String> activeVersion;
  final Value<String> activeSha256;
  final Value<String> source;
  final Value<DateTime?> lastCheckedAt;
  const DatasetStatesCompanion({
    this.id = const Value.absent(),
    this.activeVersion = const Value.absent(),
    this.activeSha256 = const Value.absent(),
    this.source = const Value.absent(),
    this.lastCheckedAt = const Value.absent(),
  });
  DatasetStatesCompanion.insert({
    this.id = const Value.absent(),
    required String activeVersion,
    required String activeSha256,
    required String source,
    this.lastCheckedAt = const Value.absent(),
  }) : activeVersion = Value(activeVersion),
       activeSha256 = Value(activeSha256),
       source = Value(source);
  static Insertable<DatasetState> custom({
    Expression<int>? id,
    Expression<String>? activeVersion,
    Expression<String>? activeSha256,
    Expression<String>? source,
    Expression<DateTime>? lastCheckedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activeVersion != null) 'active_version': activeVersion,
      if (activeSha256 != null) 'active_sha256': activeSha256,
      if (source != null) 'source': source,
      if (lastCheckedAt != null) 'last_checked_at': lastCheckedAt,
    });
  }

  DatasetStatesCompanion copyWith({
    Value<int>? id,
    Value<String>? activeVersion,
    Value<String>? activeSha256,
    Value<String>? source,
    Value<DateTime?>? lastCheckedAt,
  }) {
    return DatasetStatesCompanion(
      id: id ?? this.id,
      activeVersion: activeVersion ?? this.activeVersion,
      activeSha256: activeSha256 ?? this.activeSha256,
      source: source ?? this.source,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activeVersion.present) {
      map['active_version'] = Variable<String>(activeVersion.value);
    }
    if (activeSha256.present) {
      map['active_sha256'] = Variable<String>(activeSha256.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (lastCheckedAt.present) {
      map['last_checked_at'] = Variable<DateTime>(lastCheckedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatasetStatesCompanion(')
          ..write('id: $id, ')
          ..write('activeVersion: $activeVersion, ')
          ..write('activeSha256: $activeSha256, ')
          ..write('source: $source, ')
          ..write('lastCheckedAt: $lastCheckedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserFilmsTable userFilms = $UserFilmsTable(this);
  late final $UserDevelopersTable userDevelopers = $UserDevelopersTable(this);
  late final $RecipesTable recipes = $RecipesTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $ProcessesTable processes = $ProcessesTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $FavouritesTable favourites = $FavouritesTable(this);
  late final $SettingsRowsTable settingsRows = $SettingsRowsTable(this);
  late final $DatasetStatesTable datasetStates = $DatasetStatesTable(this);
  late final Index recipesKey = Index(
    'recipes_key',
    'CREATE INDEX recipes_key ON recipes (key_canonical)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userFilms,
    userDevelopers,
    recipes,
    notes,
    processes,
    sessions,
    favourites,
    settingsRows,
    datasetStates,
    recipesKey,
  ];
}

typedef $$UserFilmsTableCreateCompanionBuilder = UserFilmsCompanion Function({
  required String id,
  required String brand,
  required String name,
  required int boxIso,
  Value<String?> matchedCatalogId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$UserFilmsTableUpdateCompanionBuilder = UserFilmsCompanion Function({
  Value<String> id,
  Value<String> brand,
  Value<String> name,
  Value<int> boxIso,
  Value<String?> matchedCatalogId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$UserFilmsTableFilterComposer
    extends Composer<_$AppDatabase, $UserFilmsTable> {
  $$UserFilmsTableFilterComposer({
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

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get boxIso => $composableBuilder(
    column: $table.boxIso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchedCatalogId => $composableBuilder(
    column: $table.matchedCatalogId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserFilmsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserFilmsTable> {
  $$UserFilmsTableOrderingComposer({
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

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get boxIso => $composableBuilder(
    column: $table.boxIso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchedCatalogId => $composableBuilder(
    column: $table.matchedCatalogId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserFilmsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserFilmsTable> {
  $$UserFilmsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get boxIso =>
      $composableBuilder(column: $table.boxIso, builder: (column) => column);

  GeneratedColumn<String> get matchedCatalogId => $composableBuilder(
    column: $table.matchedCatalogId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserFilmsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserFilmsTable,
          UserFilmRow,
          $$UserFilmsTableFilterComposer,
          $$UserFilmsTableOrderingComposer,
          $$UserFilmsTableAnnotationComposer,
          $$UserFilmsTableCreateCompanionBuilder,
          $$UserFilmsTableUpdateCompanionBuilder,
          (
            UserFilmRow,
            BaseReferences<_$AppDatabase, $UserFilmsTable, UserFilmRow>,
          ),
          UserFilmRow,
          PrefetchHooks Function()
        > {
  $$UserFilmsTableTableManager(_$AppDatabase db, $UserFilmsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserFilmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserFilmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserFilmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> boxIso = const Value.absent(),
                Value<String?> matchedCatalogId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserFilmsCompanion(
                id: id,
                brand: brand,
                name: name,
                boxIso: boxIso,
                matchedCatalogId: matchedCatalogId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String brand,
                required String name,
                required int boxIso,
                Value<String?> matchedCatalogId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => UserFilmsCompanion.insert(
                id: id,
                brand: brand,
                name: name,
                boxIso: boxIso,
                matchedCatalogId: matchedCatalogId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserFilmsTable, UserFilmRow>(table),
                  BaseReferences<_$AppDatabase, $UserFilmsTable, UserFilmRow>(
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

typedef $$UserFilmsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserFilmsTable,
      UserFilmRow,
      $$UserFilmsTableFilterComposer,
      $$UserFilmsTableOrderingComposer,
      $$UserFilmsTableAnnotationComposer,
      $$UserFilmsTableCreateCompanionBuilder,
      $$UserFilmsTableUpdateCompanionBuilder,
      (
        UserFilmRow,
        BaseReferences<_$AppDatabase, $UserFilmsTable, UserFilmRow>,
      ),
      UserFilmRow,
      PrefetchHooks Function()
    >;
typedef $$UserDevelopersTableCreateCompanionBuilder =
    UserDevelopersCompanion Function({
      required String id,
      required String brand,
      required String name,
      Value<String?> matchedCatalogId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$UserDevelopersTableUpdateCompanionBuilder =
    UserDevelopersCompanion Function({
      Value<String> id,
      Value<String> brand,
      Value<String> name,
      Value<String?> matchedCatalogId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$UserDevelopersTableFilterComposer
    extends Composer<_$AppDatabase, $UserDevelopersTable> {
  $$UserDevelopersTableFilterComposer({
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

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchedCatalogId => $composableBuilder(
    column: $table.matchedCatalogId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserDevelopersTableOrderingComposer
    extends Composer<_$AppDatabase, $UserDevelopersTable> {
  $$UserDevelopersTableOrderingComposer({
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

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchedCatalogId => $composableBuilder(
    column: $table.matchedCatalogId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserDevelopersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserDevelopersTable> {
  $$UserDevelopersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get matchedCatalogId => $composableBuilder(
    column: $table.matchedCatalogId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UserDevelopersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserDevelopersTable,
          UserDeveloperRow,
          $$UserDevelopersTableFilterComposer,
          $$UserDevelopersTableOrderingComposer,
          $$UserDevelopersTableAnnotationComposer,
          $$UserDevelopersTableCreateCompanionBuilder,
          $$UserDevelopersTableUpdateCompanionBuilder,
          (
            UserDeveloperRow,
            BaseReferences<
              _$AppDatabase,
              $UserDevelopersTable,
              UserDeveloperRow
            >,
          ),
          UserDeveloperRow,
          PrefetchHooks Function()
        > {
  $$UserDevelopersTableTableManager(
    _$AppDatabase db,
    $UserDevelopersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserDevelopersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserDevelopersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserDevelopersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> matchedCatalogId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserDevelopersCompanion(
                id: id,
                brand: brand,
                name: name,
                matchedCatalogId: matchedCatalogId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String brand,
                required String name,
                Value<String?> matchedCatalogId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => UserDevelopersCompanion.insert(
                id: id,
                brand: brand,
                name: name,
                matchedCatalogId: matchedCatalogId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserDevelopersTable, UserDeveloperRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UserDevelopersTable,
                    UserDeveloperRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserDevelopersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserDevelopersTable,
      UserDeveloperRow,
      $$UserDevelopersTableFilterComposer,
      $$UserDevelopersTableOrderingComposer,
      $$UserDevelopersTableAnnotationComposer,
      $$UserDevelopersTableCreateCompanionBuilder,
      $$UserDevelopersTableUpdateCompanionBuilder,
      (
        UserDeveloperRow,
        BaseReferences<_$AppDatabase, $UserDevelopersTable, UserDeveloperRow>,
      ),
      UserDeveloperRow,
      PrefetchHooks Function()
    >;
typedef $$RecipesTableCreateCompanionBuilder = RecipesCompanion Function({
  required String id,
  required int version,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String authorName,
  required String ownership,
  required String originJson,
  Value<DateTime?> importedAt,
  required String keyCanonical,
  required String keyJson,
  required int devTimeS,
  required String devAgitationJson,
  Value<String?> processJson,
  Value<bool> hidden,
  Value<int> rowid,
});
typedef $$RecipesTableUpdateCompanionBuilder = RecipesCompanion Function({
  Value<String> id,
  Value<int> version,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> authorName,
  Value<String> ownership,
  Value<String> originJson,
  Value<DateTime?> importedAt,
  Value<String> keyCanonical,
  Value<String> keyJson,
  Value<int> devTimeS,
  Value<String> devAgitationJson,
  Value<String?> processJson,
  Value<bool> hidden,
  Value<int> rowid,
});

final class $$RecipesTableReferences
    extends BaseReferences<_$AppDatabase, $RecipesTable, RecipeRow> {
  $$RecipesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NotesTable, List<NoteRow>> _notesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.notes,
    aliasName: 'recipes__id__notes__recipe_id',
  );

  $$NotesTableProcessedTableManager get notesRefs {
    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_notesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownership => $composableBuilder(
    column: $table.ownership,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originJson => $composableBuilder(
    column: $table.originJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyCanonical => $composableBuilder(
    column: $table.keyCanonical,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyJson => $composableBuilder(
    column: $table.keyJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get devTimeS => $composableBuilder(
    column: $table.devTimeS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devAgitationJson => $composableBuilder(
    column: $table.devAgitationJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get processJson => $composableBuilder(
    column: $table.processJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> notesRefs(
    Expression<bool> Function($$NotesTableFilterComposer f) f,
  ) {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownership => $composableBuilder(
    column: $table.ownership,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originJson => $composableBuilder(
    column: $table.originJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyCanonical => $composableBuilder(
    column: $table.keyCanonical,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyJson => $composableBuilder(
    column: $table.keyJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get devTimeS => $composableBuilder(
    column: $table.devTimeS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devAgitationJson => $composableBuilder(
    column: $table.devAgitationJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processJson => $composableBuilder(
    column: $table.processJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownership =>
      $composableBuilder(column: $table.ownership, builder: (column) => column);

  GeneratedColumn<String> get originJson => $composableBuilder(
    column: $table.originJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keyCanonical => $composableBuilder(
    column: $table.keyCanonical,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keyJson =>
      $composableBuilder(column: $table.keyJson, builder: (column) => column);

  GeneratedColumn<int> get devTimeS =>
      $composableBuilder(column: $table.devTimeS, builder: (column) => column);

  GeneratedColumn<String> get devAgitationJson => $composableBuilder(
    column: $table.devAgitationJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get processJson => $composableBuilder(
    column: $table.processJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  Expression<T> notesRefs<T extends Object>(
    Expression<T> Function($$NotesTableAnnotationComposer a) f,
  ) {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecipesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipesTable,
          RecipeRow,
          $$RecipesTableFilterComposer,
          $$RecipesTableOrderingComposer,
          $$RecipesTableAnnotationComposer,
          $$RecipesTableCreateCompanionBuilder,
          $$RecipesTableUpdateCompanionBuilder,
          (RecipeRow, $$RecipesTableReferences),
          RecipeRow,
          PrefetchHooks Function({bool notesRefs})
        > {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> authorName = const Value.absent(),
                Value<String> ownership = const Value.absent(),
                Value<String> originJson = const Value.absent(),
                Value<DateTime?> importedAt = const Value.absent(),
                Value<String> keyCanonical = const Value.absent(),
                Value<String> keyJson = const Value.absent(),
                Value<int> devTimeS = const Value.absent(),
                Value<String> devAgitationJson = const Value.absent(),
                Value<String?> processJson = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipesCompanion(
                id: id,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                authorName: authorName,
                ownership: ownership,
                originJson: originJson,
                importedAt: importedAt,
                keyCanonical: keyCanonical,
                keyJson: keyJson,
                devTimeS: devTimeS,
                devAgitationJson: devAgitationJson,
                processJson: processJson,
                hidden: hidden,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int version,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String authorName,
                required String ownership,
                required String originJson,
                Value<DateTime?> importedAt = const Value.absent(),
                required String keyCanonical,
                required String keyJson,
                required int devTimeS,
                required String devAgitationJson,
                Value<String?> processJson = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipesCompanion.insert(
                id: id,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                authorName: authorName,
                ownership: ownership,
                originJson: originJson,
                importedAt: importedAt,
                keyCanonical: keyCanonical,
                keyJson: keyJson,
                devTimeS: devTimeS,
                devAgitationJson: devAgitationJson,
                processJson: processJson,
                hidden: hidden,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecipesTable, RecipeRow>(table),
                  $$RecipesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({notesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (notesRefs) db.notes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (notesRefs)
                    await $_getPrefetchedData<
                      RecipeRow,
                      $RecipesTable,
                      NoteRow
                    >(
                      currentTable: table,
                      referencedTable: $$RecipesTableReferences._notesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$RecipesTableReferences(db, table, p0).notesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.recipeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RecipesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipesTable,
      RecipeRow,
      $$RecipesTableFilterComposer,
      $$RecipesTableOrderingComposer,
      $$RecipesTableAnnotationComposer,
      $$RecipesTableCreateCompanionBuilder,
      $$RecipesTableUpdateCompanionBuilder,
      (RecipeRow, $$RecipesTableReferences),
      RecipeRow,
      PrefetchHooks Function({bool notesRefs})
    >;
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  required String id,
  required String recipeId,
  required String authorName,
  required DateTime createdAt,
  required String text_,
  Value<int> rowid,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<String> id,
  Value<String> recipeId,
  Value<String> authorName,
  Value<DateTime> createdAt,
  Value<String> text_,
  Value<int> rowid,
});

final class $$NotesTableReferences
    extends BaseReferences<_$AppDatabase, $NotesTable, NoteRow> {
  $$NotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('notes__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
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

  ColumnFilters<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get text_ => $composableBuilder(
    column: $table.text_,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
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

  ColumnOrderings<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get text_ => $composableBuilder(
    column: $table.text_,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get text_ =>
      $composableBuilder(column: $table.text_, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          NoteRow,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (NoteRow, $$NotesTableReferences),
          NoteRow,
          PrefetchHooks Function({bool recipeId})
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recipeId = const Value.absent(),
                Value<String> authorName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> text_ = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                recipeId: recipeId,
                authorName: authorName,
                createdAt: createdAt,
                text_: text_,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recipeId,
                required String authorName,
                required DateTime createdAt,
                required String text_,
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                recipeId: recipeId,
                authorName: authorName,
                createdAt: createdAt,
                text_: text_,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotesTable, NoteRow>(table),
                  $$NotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
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
                    if (recipeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.recipeId,
                        referencedTable: $$NotesTableReferences._recipeIdTable(
                          db,
                        ),
                        referencedColumn: $$NotesTableReferences
                            ._recipeIdTable(db)
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

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      NoteRow,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (NoteRow, $$NotesTableReferences),
      NoteRow,
      PrefetchHooks Function({bool recipeId})
    >;
typedef $$ProcessesTableCreateCompanionBuilder = ProcessesCompanion Function({
  required String id,
  required String json,
  Value<int> rowid,
});
typedef $$ProcessesTableUpdateCompanionBuilder = ProcessesCompanion Function({
  Value<String> id,
  Value<String> json,
  Value<int> rowid,
});

class $$ProcessesTableFilterComposer
    extends Composer<_$AppDatabase, $ProcessesTable> {
  $$ProcessesTableFilterComposer({
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

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProcessesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProcessesTable> {
  $$ProcessesTableOrderingComposer({
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

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProcessesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProcessesTable> {
  $$ProcessesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$ProcessesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProcessesTable,
          ProcessesData,
          $$ProcessesTableFilterComposer,
          $$ProcessesTableOrderingComposer,
          $$ProcessesTableAnnotationComposer,
          $$ProcessesTableCreateCompanionBuilder,
          $$ProcessesTableUpdateCompanionBuilder,
          (
            ProcessesData,
            BaseReferences<_$AppDatabase, $ProcessesTable, ProcessesData>,
          ),
          ProcessesData,
          PrefetchHooks Function()
        > {
  $$ProcessesTableTableManager(_$AppDatabase db, $ProcessesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProcessesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProcessesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProcessesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ProcessesCompanion(id: id, json: json, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            required String json,
            Value<int> rowid = const Value.absent(),
          }) => ProcessesCompanion.insert(id: id, json: json, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProcessesTable, ProcessesData>(table),
                  BaseReferences<_$AppDatabase, $ProcessesTable, ProcessesData>(
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

typedef $$ProcessesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProcessesTable,
      ProcessesData,
      $$ProcessesTableFilterComposer,
      $$ProcessesTableOrderingComposer,
      $$ProcessesTableAnnotationComposer,
      $$ProcessesTableCreateCompanionBuilder,
      $$ProcessesTableUpdateCompanionBuilder,
      (
        ProcessesData,
        BaseReferences<_$AppDatabase, $ProcessesTable, ProcessesData>,
      ),
      ProcessesData,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String id,
  required int tankSlot,
  required String tankLabel,
  Value<String?> keyCanonical,
  Value<String?> keyJson,
  required String timeSourceJson,
  required int devTimeS,
  required String format,
  required int volumeMl,
  required String processSnapshotJson,
  required double inversionPaceS,
  required String status,
  Value<int?> abortedAtStep,
  required DateTime startedAt,
  Value<DateTime?> finishedAt,
  required String stepRunsJson,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<int> tankSlot,
  Value<String> tankLabel,
  Value<String?> keyCanonical,
  Value<String?> keyJson,
  Value<String> timeSourceJson,
  Value<int> devTimeS,
  Value<String> format,
  Value<int> volumeMl,
  Value<String> processSnapshotJson,
  Value<double> inversionPaceS,
  Value<String> status,
  Value<int?> abortedAtStep,
  Value<DateTime> startedAt,
  Value<DateTime?> finishedAt,
  Value<String> stepRunsJson,
  Value<int> rowid,
});

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
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

  ColumnFilters<int> get tankSlot => $composableBuilder(
    column: $table.tankSlot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tankLabel => $composableBuilder(
    column: $table.tankLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyCanonical => $composableBuilder(
    column: $table.keyCanonical,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyJson => $composableBuilder(
    column: $table.keyJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeSourceJson => $composableBuilder(
    column: $table.timeSourceJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get devTimeS => $composableBuilder(
    column: $table.devTimeS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get volumeMl => $composableBuilder(
    column: $table.volumeMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get processSnapshotJson => $composableBuilder(
    column: $table.processSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get inversionPaceS => $composableBuilder(
    column: $table.inversionPaceS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get abortedAtStep => $composableBuilder(
    column: $table.abortedAtStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stepRunsJson => $composableBuilder(
    column: $table.stepRunsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
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

  ColumnOrderings<int> get tankSlot => $composableBuilder(
    column: $table.tankSlot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tankLabel => $composableBuilder(
    column: $table.tankLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyCanonical => $composableBuilder(
    column: $table.keyCanonical,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyJson => $composableBuilder(
    column: $table.keyJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeSourceJson => $composableBuilder(
    column: $table.timeSourceJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get devTimeS => $composableBuilder(
    column: $table.devTimeS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get volumeMl => $composableBuilder(
    column: $table.volumeMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processSnapshotJson => $composableBuilder(
    column: $table.processSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get inversionPaceS => $composableBuilder(
    column: $table.inversionPaceS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get abortedAtStep => $composableBuilder(
    column: $table.abortedAtStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stepRunsJson => $composableBuilder(
    column: $table.stepRunsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tankSlot =>
      $composableBuilder(column: $table.tankSlot, builder: (column) => column);

  GeneratedColumn<String> get tankLabel =>
      $composableBuilder(column: $table.tankLabel, builder: (column) => column);

  GeneratedColumn<String> get keyCanonical => $composableBuilder(
    column: $table.keyCanonical,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keyJson =>
      $composableBuilder(column: $table.keyJson, builder: (column) => column);

  GeneratedColumn<String> get timeSourceJson => $composableBuilder(
    column: $table.timeSourceJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get devTimeS =>
      $composableBuilder(column: $table.devTimeS, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<int> get volumeMl =>
      $composableBuilder(column: $table.volumeMl, builder: (column) => column);

  GeneratedColumn<String> get processSnapshotJson => $composableBuilder(
    column: $table.processSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get inversionPaceS => $composableBuilder(
    column: $table.inversionPaceS,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get abortedAtStep => $composableBuilder(
    column: $table.abortedAtStep,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stepRunsJson => $composableBuilder(
    column: $table.stepRunsJson,
    builder: (column) => column,
  );
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> tankSlot = const Value.absent(),
                Value<String> tankLabel = const Value.absent(),
                Value<String?> keyCanonical = const Value.absent(),
                Value<String?> keyJson = const Value.absent(),
                Value<String> timeSourceJson = const Value.absent(),
                Value<int> devTimeS = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<int> volumeMl = const Value.absent(),
                Value<String> processSnapshotJson = const Value.absent(),
                Value<double> inversionPaceS = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> abortedAtStep = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<String> stepRunsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                tankSlot: tankSlot,
                tankLabel: tankLabel,
                keyCanonical: keyCanonical,
                keyJson: keyJson,
                timeSourceJson: timeSourceJson,
                devTimeS: devTimeS,
                format: format,
                volumeMl: volumeMl,
                processSnapshotJson: processSnapshotJson,
                inversionPaceS: inversionPaceS,
                status: status,
                abortedAtStep: abortedAtStep,
                startedAt: startedAt,
                finishedAt: finishedAt,
                stepRunsJson: stepRunsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int tankSlot,
                required String tankLabel,
                Value<String?> keyCanonical = const Value.absent(),
                Value<String?> keyJson = const Value.absent(),
                required String timeSourceJson,
                required int devTimeS,
                required String format,
                required int volumeMl,
                required String processSnapshotJson,
                required double inversionPaceS,
                required String status,
                Value<int?> abortedAtStep = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                required String stepRunsJson,
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                tankSlot: tankSlot,
                tankLabel: tankLabel,
                keyCanonical: keyCanonical,
                keyJson: keyJson,
                timeSourceJson: timeSourceJson,
                devTimeS: devTimeS,
                format: format,
                volumeMl: volumeMl,
                processSnapshotJson: processSnapshotJson,
                inversionPaceS: inversionPaceS,
                status: status,
                abortedAtStep: abortedAtStep,
                startedAt: startedAt,
                finishedAt: finishedAt,
                stepRunsJson: stepRunsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, Session>(table),
                  BaseReferences<_$AppDatabase, $SessionsTable, Session>(
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

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$FavouritesTableCreateCompanionBuilder = FavouritesCompanion Function({
  required String keyCanonical,
  required String keyJson,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$FavouritesTableUpdateCompanionBuilder = FavouritesCompanion Function({
  Value<String> keyCanonical,
  Value<String> keyJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$FavouritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavouritesTable> {
  $$FavouritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get keyCanonical => $composableBuilder(
    column: $table.keyCanonical,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyJson => $composableBuilder(
    column: $table.keyJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavouritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavouritesTable> {
  $$FavouritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get keyCanonical => $composableBuilder(
    column: $table.keyCanonical,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyJson => $composableBuilder(
    column: $table.keyJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavouritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavouritesTable> {
  $$FavouritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get keyCanonical => $composableBuilder(
    column: $table.keyCanonical,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keyJson =>
      $composableBuilder(column: $table.keyJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FavouritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavouritesTable,
          Favourite,
          $$FavouritesTableFilterComposer,
          $$FavouritesTableOrderingComposer,
          $$FavouritesTableAnnotationComposer,
          $$FavouritesTableCreateCompanionBuilder,
          $$FavouritesTableUpdateCompanionBuilder,
          (
            Favourite,
            BaseReferences<_$AppDatabase, $FavouritesTable, Favourite>,
          ),
          Favourite,
          PrefetchHooks Function()
        > {
  $$FavouritesTableTableManager(_$AppDatabase db, $FavouritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavouritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavouritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavouritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> keyCanonical = const Value.absent(),
                Value<String> keyJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavouritesCompanion(
                keyCanonical: keyCanonical,
                keyJson: keyJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String keyCanonical,
                required String keyJson,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => FavouritesCompanion.insert(
                keyCanonical: keyCanonical,
                keyJson: keyJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavouritesTable, Favourite>(table),
                  BaseReferences<_$AppDatabase, $FavouritesTable, Favourite>(
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

typedef $$FavouritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavouritesTable,
      Favourite,
      $$FavouritesTableFilterComposer,
      $$FavouritesTableOrderingComposer,
      $$FavouritesTableAnnotationComposer,
      $$FavouritesTableCreateCompanionBuilder,
      $$FavouritesTableUpdateCompanionBuilder,
      (Favourite, BaseReferences<_$AppDatabase, $FavouritesTable, Favourite>),
      Favourite,
      PrefetchHooks Function()
    >;
typedef $$SettingsRowsTableCreateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      Value<String> authorName,
      Value<int> volume35mmMl,
      Value<int> volume120Ml,
      Value<String> defaultProcessId,
      Value<double> inversionPaceS,
      Value<bool> soundOn,
      Value<double> volume,
      Value<bool> volumeKeyNext,
      Value<String> tempUnit,
      Value<String> theme,
      Value<String> lastMode,
      Value<bool> backgroundLimitSeen,
      Value<bool> notificationsAsked,
      Value<String> lastFormat,
    });
typedef $$SettingsRowsTableUpdateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      Value<String> authorName,
      Value<int> volume35mmMl,
      Value<int> volume120Ml,
      Value<String> defaultProcessId,
      Value<double> inversionPaceS,
      Value<bool> soundOn,
      Value<double> volume,
      Value<bool> volumeKeyNext,
      Value<String> tempUnit,
      Value<String> theme,
      Value<String> lastMode,
      Value<bool> backgroundLimitSeen,
      Value<bool> notificationsAsked,
      Value<String> lastFormat,
    });

class $$SettingsRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get volume35mmMl => $composableBuilder(
    column: $table.volume35mmMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get volume120Ml => $composableBuilder(
    column: $table.volume120Ml,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultProcessId => $composableBuilder(
    column: $table.defaultProcessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get inversionPaceS => $composableBuilder(
    column: $table.inversionPaceS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get soundOn => $composableBuilder(
    column: $table.soundOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get volume => $composableBuilder(
    column: $table.volume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get volumeKeyNext => $composableBuilder(
    column: $table.volumeKeyNext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tempUnit => $composableBuilder(
    column: $table.tempUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMode => $composableBuilder(
    column: $table.lastMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get backgroundLimitSeen => $composableBuilder(
    column: $table.backgroundLimitSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationsAsked => $composableBuilder(
    column: $table.notificationsAsked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastFormat => $composableBuilder(
    column: $table.lastFormat,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get volume35mmMl => $composableBuilder(
    column: $table.volume35mmMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get volume120Ml => $composableBuilder(
    column: $table.volume120Ml,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultProcessId => $composableBuilder(
    column: $table.defaultProcessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get inversionPaceS => $composableBuilder(
    column: $table.inversionPaceS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get soundOn => $composableBuilder(
    column: $table.soundOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get volume => $composableBuilder(
    column: $table.volume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get volumeKeyNext => $composableBuilder(
    column: $table.volumeKeyNext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tempUnit => $composableBuilder(
    column: $table.tempUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMode => $composableBuilder(
    column: $table.lastMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get backgroundLimitSeen => $composableBuilder(
    column: $table.backgroundLimitSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationsAsked => $composableBuilder(
    column: $table.notificationsAsked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastFormat => $composableBuilder(
    column: $table.lastFormat,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get volume35mmMl => $composableBuilder(
    column: $table.volume35mmMl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get volume120Ml => $composableBuilder(
    column: $table.volume120Ml,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultProcessId => $composableBuilder(
    column: $table.defaultProcessId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get inversionPaceS => $composableBuilder(
    column: $table.inversionPaceS,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get soundOn =>
      $composableBuilder(column: $table.soundOn, builder: (column) => column);

  GeneratedColumn<double> get volume =>
      $composableBuilder(column: $table.volume, builder: (column) => column);

  GeneratedColumn<bool> get volumeKeyNext => $composableBuilder(
    column: $table.volumeKeyNext,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tempUnit =>
      $composableBuilder(column: $table.tempUnit, builder: (column) => column);

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<String> get lastMode =>
      $composableBuilder(column: $table.lastMode, builder: (column) => column);

  GeneratedColumn<bool> get backgroundLimitSeen => $composableBuilder(
    column: $table.backgroundLimitSeen,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notificationsAsked => $composableBuilder(
    column: $table.notificationsAsked,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastFormat => $composableBuilder(
    column: $table.lastFormat,
    builder: (column) => column,
  );
}

class $$SettingsRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsRowsTable,
          SettingsRow,
          $$SettingsRowsTableFilterComposer,
          $$SettingsRowsTableOrderingComposer,
          $$SettingsRowsTableAnnotationComposer,
          $$SettingsRowsTableCreateCompanionBuilder,
          $$SettingsRowsTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$AppDatabase, $SettingsRowsTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsRowsTableTableManager(_$AppDatabase db, $SettingsRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> authorName = const Value.absent(),
                Value<int> volume35mmMl = const Value.absent(),
                Value<int> volume120Ml = const Value.absent(),
                Value<String> defaultProcessId = const Value.absent(),
                Value<double> inversionPaceS = const Value.absent(),
                Value<bool> soundOn = const Value.absent(),
                Value<double> volume = const Value.absent(),
                Value<bool> volumeKeyNext = const Value.absent(),
                Value<String> tempUnit = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String> lastMode = const Value.absent(),
                Value<bool> backgroundLimitSeen = const Value.absent(),
                Value<bool> notificationsAsked = const Value.absent(),
                Value<String> lastFormat = const Value.absent(),
              }) => SettingsRowsCompanion(
                id: id,
                authorName: authorName,
                volume35mmMl: volume35mmMl,
                volume120Ml: volume120Ml,
                defaultProcessId: defaultProcessId,
                inversionPaceS: inversionPaceS,
                soundOn: soundOn,
                volume: volume,
                volumeKeyNext: volumeKeyNext,
                tempUnit: tempUnit,
                theme: theme,
                lastMode: lastMode,
                backgroundLimitSeen: backgroundLimitSeen,
                notificationsAsked: notificationsAsked,
                lastFormat: lastFormat,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> authorName = const Value.absent(),
                Value<int> volume35mmMl = const Value.absent(),
                Value<int> volume120Ml = const Value.absent(),
                Value<String> defaultProcessId = const Value.absent(),
                Value<double> inversionPaceS = const Value.absent(),
                Value<bool> soundOn = const Value.absent(),
                Value<double> volume = const Value.absent(),
                Value<bool> volumeKeyNext = const Value.absent(),
                Value<String> tempUnit = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String> lastMode = const Value.absent(),
                Value<bool> backgroundLimitSeen = const Value.absent(),
                Value<bool> notificationsAsked = const Value.absent(),
                Value<String> lastFormat = const Value.absent(),
              }) => SettingsRowsCompanion.insert(
                id: id,
                authorName: authorName,
                volume35mmMl: volume35mmMl,
                volume120Ml: volume120Ml,
                defaultProcessId: defaultProcessId,
                inversionPaceS: inversionPaceS,
                soundOn: soundOn,
                volume: volume,
                volumeKeyNext: volumeKeyNext,
                tempUnit: tempUnit,
                theme: theme,
                lastMode: lastMode,
                backgroundLimitSeen: backgroundLimitSeen,
                notificationsAsked: notificationsAsked,
                lastFormat: lastFormat,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsRowsTable, SettingsRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SettingsRowsTable,
                    SettingsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsRowsTable,
      SettingsRow,
      $$SettingsRowsTableFilterComposer,
      $$SettingsRowsTableOrderingComposer,
      $$SettingsRowsTableAnnotationComposer,
      $$SettingsRowsTableCreateCompanionBuilder,
      $$SettingsRowsTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$AppDatabase, $SettingsRowsTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;
typedef $$DatasetStatesTableCreateCompanionBuilder =
    DatasetStatesCompanion Function({
      Value<int> id,
      required String activeVersion,
      required String activeSha256,
      required String source,
      Value<DateTime?> lastCheckedAt,
    });
typedef $$DatasetStatesTableUpdateCompanionBuilder =
    DatasetStatesCompanion Function({
      Value<int> id,
      Value<String> activeVersion,
      Value<String> activeSha256,
      Value<String> source,
      Value<DateTime?> lastCheckedAt,
    });

class $$DatasetStatesTableFilterComposer
    extends Composer<_$AppDatabase, $DatasetStatesTable> {
  $$DatasetStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeVersion => $composableBuilder(
    column: $table.activeVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeSha256 => $composableBuilder(
    column: $table.activeSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DatasetStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $DatasetStatesTable> {
  $$DatasetStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeVersion => $composableBuilder(
    column: $table.activeVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeSha256 => $composableBuilder(
    column: $table.activeSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DatasetStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatasetStatesTable> {
  $$DatasetStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activeVersion => $composableBuilder(
    column: $table.activeVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeSha256 => $composableBuilder(
    column: $table.activeSha256,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => column,
  );
}

class $$DatasetStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DatasetStatesTable,
          DatasetState,
          $$DatasetStatesTableFilterComposer,
          $$DatasetStatesTableOrderingComposer,
          $$DatasetStatesTableAnnotationComposer,
          $$DatasetStatesTableCreateCompanionBuilder,
          $$DatasetStatesTableUpdateCompanionBuilder,
          (
            DatasetState,
            BaseReferences<_$AppDatabase, $DatasetStatesTable, DatasetState>,
          ),
          DatasetState,
          PrefetchHooks Function()
        > {
  $$DatasetStatesTableTableManager(_$AppDatabase db, $DatasetStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatasetStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DatasetStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatasetStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> activeVersion = const Value.absent(),
                Value<String> activeSha256 = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime?> lastCheckedAt = const Value.absent(),
              }) => DatasetStatesCompanion(
                id: id,
                activeVersion: activeVersion,
                activeSha256: activeSha256,
                source: source,
                lastCheckedAt: lastCheckedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String activeVersion,
                required String activeSha256,
                required String source,
                Value<DateTime?> lastCheckedAt = const Value.absent(),
              }) => DatasetStatesCompanion.insert(
                id: id,
                activeVersion: activeVersion,
                activeSha256: activeSha256,
                source: source,
                lastCheckedAt: lastCheckedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DatasetStatesTable, DatasetState>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DatasetStatesTable,
                    DatasetState
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DatasetStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DatasetStatesTable,
      DatasetState,
      $$DatasetStatesTableFilterComposer,
      $$DatasetStatesTableOrderingComposer,
      $$DatasetStatesTableAnnotationComposer,
      $$DatasetStatesTableCreateCompanionBuilder,
      $$DatasetStatesTableUpdateCompanionBuilder,
      (
        DatasetState,
        BaseReferences<_$AppDatabase, $DatasetStatesTable, DatasetState>,
      ),
      DatasetState,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserFilmsTableTableManager get userFilms =>
      $$UserFilmsTableTableManager(_db, _db.userFilms);
  $$UserDevelopersTableTableManager get userDevelopers =>
      $$UserDevelopersTableTableManager(_db, _db.userDevelopers);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$ProcessesTableTableManager get processes =>
      $$ProcessesTableTableManager(_db, _db.processes);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$FavouritesTableTableManager get favourites =>
      $$FavouritesTableTableManager(_db, _db.favourites);
  $$SettingsRowsTableTableManager get settingsRows =>
      $$SettingsRowsTableTableManager(_db, _db.settingsRows);
  $$DatasetStatesTableTableManager get datasetStates =>
      $$DatasetStatesTableTableManager(_db, _db.datasetStates);
}
