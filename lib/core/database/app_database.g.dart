// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TokenPurchasesTable extends TokenPurchases
    with TableInfo<$TokenPurchasesTable, TokenPurchase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TokenPurchasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kWhAmountMeta = const VerificationMeta(
    'kWhAmount',
  );
  @override
  late final GeneratedColumn<double> kWhAmount = GeneratedColumn<double>(
    'k_wh_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, kWhAmount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'token_purchases';
  @override
  VerificationContext validateIntegrity(
    Insertable<TokenPurchase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('k_wh_amount')) {
      context.handle(
        _kWhAmountMeta,
        kWhAmount.isAcceptableOrUnknown(data['k_wh_amount']!, _kWhAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_kWhAmountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TokenPurchase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TokenPurchase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      kWhAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}k_wh_amount'],
      )!,
    );
  }

  @override
  $TokenPurchasesTable createAlias(String alias) {
    return $TokenPurchasesTable(attachedDatabase, alias);
  }
}

class TokenPurchase extends DataClass implements Insertable<TokenPurchase> {
  final int id;
  final DateTime date;
  final double kWhAmount;
  const TokenPurchase({
    required this.id,
    required this.date,
    required this.kWhAmount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['k_wh_amount'] = Variable<double>(kWhAmount);
    return map;
  }

  TokenPurchasesCompanion toCompanion(bool nullToAbsent) {
    return TokenPurchasesCompanion(
      id: Value(id),
      date: Value(date),
      kWhAmount: Value(kWhAmount),
    );
  }

  factory TokenPurchase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TokenPurchase(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      kWhAmount: serializer.fromJson<double>(json['kWhAmount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'kWhAmount': serializer.toJson<double>(kWhAmount),
    };
  }

  TokenPurchase copyWith({int? id, DateTime? date, double? kWhAmount}) =>
      TokenPurchase(
        id: id ?? this.id,
        date: date ?? this.date,
        kWhAmount: kWhAmount ?? this.kWhAmount,
      );
  TokenPurchase copyWithCompanion(TokenPurchasesCompanion data) {
    return TokenPurchase(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      kWhAmount: data.kWhAmount.present ? data.kWhAmount.value : this.kWhAmount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TokenPurchase(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('kWhAmount: $kWhAmount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, kWhAmount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TokenPurchase &&
          other.id == this.id &&
          other.date == this.date &&
          other.kWhAmount == this.kWhAmount);
}

class TokenPurchasesCompanion extends UpdateCompanion<TokenPurchase> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<double> kWhAmount;
  const TokenPurchasesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.kWhAmount = const Value.absent(),
  });
  TokenPurchasesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required double kWhAmount,
  }) : date = Value(date),
       kWhAmount = Value(kWhAmount);
  static Insertable<TokenPurchase> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<double>? kWhAmount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (kWhAmount != null) 'k_wh_amount': kWhAmount,
    });
  }

  TokenPurchasesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<double>? kWhAmount,
  }) {
    return TokenPurchasesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      kWhAmount: kWhAmount ?? this.kWhAmount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (kWhAmount.present) {
      map['k_wh_amount'] = Variable<double>(kWhAmount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TokenPurchasesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('kWhAmount: $kWhAmount')
          ..write(')'))
        .toString();
  }
}

class $MeterCheckInsTable extends MeterCheckIns
    with TableInfo<$MeterCheckInsTable, MeterCheckIn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeterCheckInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remainingKWhMeta = const VerificationMeta(
    'remainingKWh',
  );
  @override
  late final GeneratedColumn<double> remainingKWh = GeneratedColumn<double>(
    'remaining_k_wh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, date, remainingKWh];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meter_check_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeterCheckIn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('remaining_k_wh')) {
      context.handle(
        _remainingKWhMeta,
        remainingKWh.isAcceptableOrUnknown(
          data['remaining_k_wh']!,
          _remainingKWhMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remainingKWhMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeterCheckIn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeterCheckIn(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      remainingKWh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}remaining_k_wh'],
      )!,
    );
  }

  @override
  $MeterCheckInsTable createAlias(String alias) {
    return $MeterCheckInsTable(attachedDatabase, alias);
  }
}

class MeterCheckIn extends DataClass implements Insertable<MeterCheckIn> {
  final int id;
  final DateTime date;
  final double remainingKWh;
  const MeterCheckIn({
    required this.id,
    required this.date,
    required this.remainingKWh,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['remaining_k_wh'] = Variable<double>(remainingKWh);
    return map;
  }

  MeterCheckInsCompanion toCompanion(bool nullToAbsent) {
    return MeterCheckInsCompanion(
      id: Value(id),
      date: Value(date),
      remainingKWh: Value(remainingKWh),
    );
  }

  factory MeterCheckIn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeterCheckIn(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      remainingKWh: serializer.fromJson<double>(json['remainingKWh']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'remainingKWh': serializer.toJson<double>(remainingKWh),
    };
  }

  MeterCheckIn copyWith({int? id, DateTime? date, double? remainingKWh}) =>
      MeterCheckIn(
        id: id ?? this.id,
        date: date ?? this.date,
        remainingKWh: remainingKWh ?? this.remainingKWh,
      );
  MeterCheckIn copyWithCompanion(MeterCheckInsCompanion data) {
    return MeterCheckIn(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      remainingKWh: data.remainingKWh.present
          ? data.remainingKWh.value
          : this.remainingKWh,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeterCheckIn(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('remainingKWh: $remainingKWh')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, remainingKWh);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeterCheckIn &&
          other.id == this.id &&
          other.date == this.date &&
          other.remainingKWh == this.remainingKWh);
}

class MeterCheckInsCompanion extends UpdateCompanion<MeterCheckIn> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<double> remainingKWh;
  const MeterCheckInsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.remainingKWh = const Value.absent(),
  });
  MeterCheckInsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required double remainingKWh,
  }) : date = Value(date),
       remainingKWh = Value(remainingKWh);
  static Insertable<MeterCheckIn> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<double>? remainingKWh,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (remainingKWh != null) 'remaining_k_wh': remainingKWh,
    });
  }

  MeterCheckInsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<double>? remainingKWh,
  }) {
    return MeterCheckInsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      remainingKWh: remainingKWh ?? this.remainingKWh,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (remainingKWh.present) {
      map['remaining_k_wh'] = Variable<double>(remainingKWh.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeterCheckInsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('remainingKWh: $remainingKWh')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TokenPurchasesTable tokenPurchases = $TokenPurchasesTable(this);
  late final $MeterCheckInsTable meterCheckIns = $MeterCheckInsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tokenPurchases,
    meterCheckIns,
  ];
}

typedef $$TokenPurchasesTableCreateCompanionBuilder =
    TokenPurchasesCompanion Function({
      Value<int> id,
      required DateTime date,
      required double kWhAmount,
    });
typedef $$TokenPurchasesTableUpdateCompanionBuilder =
    TokenPurchasesCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<double> kWhAmount,
    });

class $$TokenPurchasesTableFilterComposer
    extends Composer<_$AppDatabase, $TokenPurchasesTable> {
  $$TokenPurchasesTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kWhAmount => $composableBuilder(
    column: $table.kWhAmount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TokenPurchasesTableOrderingComposer
    extends Composer<_$AppDatabase, $TokenPurchasesTable> {
  $$TokenPurchasesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kWhAmount => $composableBuilder(
    column: $table.kWhAmount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TokenPurchasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TokenPurchasesTable> {
  $$TokenPurchasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get kWhAmount =>
      $composableBuilder(column: $table.kWhAmount, builder: (column) => column);
}

class $$TokenPurchasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TokenPurchasesTable,
          TokenPurchase,
          $$TokenPurchasesTableFilterComposer,
          $$TokenPurchasesTableOrderingComposer,
          $$TokenPurchasesTableAnnotationComposer,
          $$TokenPurchasesTableCreateCompanionBuilder,
          $$TokenPurchasesTableUpdateCompanionBuilder,
          (
            TokenPurchase,
            BaseReferences<_$AppDatabase, $TokenPurchasesTable, TokenPurchase>,
          ),
          TokenPurchase,
          PrefetchHooks Function()
        > {
  $$TokenPurchasesTableTableManager(
    _$AppDatabase db,
    $TokenPurchasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TokenPurchasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TokenPurchasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TokenPurchasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> kWhAmount = const Value.absent(),
              }) => TokenPurchasesCompanion(
                id: id,
                date: date,
                kWhAmount: kWhAmount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required double kWhAmount,
              }) => TokenPurchasesCompanion.insert(
                id: id,
                date: date,
                kWhAmount: kWhAmount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TokenPurchasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TokenPurchasesTable,
      TokenPurchase,
      $$TokenPurchasesTableFilterComposer,
      $$TokenPurchasesTableOrderingComposer,
      $$TokenPurchasesTableAnnotationComposer,
      $$TokenPurchasesTableCreateCompanionBuilder,
      $$TokenPurchasesTableUpdateCompanionBuilder,
      (
        TokenPurchase,
        BaseReferences<_$AppDatabase, $TokenPurchasesTable, TokenPurchase>,
      ),
      TokenPurchase,
      PrefetchHooks Function()
    >;
typedef $$MeterCheckInsTableCreateCompanionBuilder =
    MeterCheckInsCompanion Function({
      Value<int> id,
      required DateTime date,
      required double remainingKWh,
    });
typedef $$MeterCheckInsTableUpdateCompanionBuilder =
    MeterCheckInsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<double> remainingKWh,
    });

class $$MeterCheckInsTableFilterComposer
    extends Composer<_$AppDatabase, $MeterCheckInsTable> {
  $$MeterCheckInsTableFilterComposer({
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get remainingKWh => $composableBuilder(
    column: $table.remainingKWh,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MeterCheckInsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeterCheckInsTable> {
  $$MeterCheckInsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get remainingKWh => $composableBuilder(
    column: $table.remainingKWh,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MeterCheckInsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeterCheckInsTable> {
  $$MeterCheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get remainingKWh => $composableBuilder(
    column: $table.remainingKWh,
    builder: (column) => column,
  );
}

class $$MeterCheckInsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MeterCheckInsTable,
          MeterCheckIn,
          $$MeterCheckInsTableFilterComposer,
          $$MeterCheckInsTableOrderingComposer,
          $$MeterCheckInsTableAnnotationComposer,
          $$MeterCheckInsTableCreateCompanionBuilder,
          $$MeterCheckInsTableUpdateCompanionBuilder,
          (
            MeterCheckIn,
            BaseReferences<_$AppDatabase, $MeterCheckInsTable, MeterCheckIn>,
          ),
          MeterCheckIn,
          PrefetchHooks Function()
        > {
  $$MeterCheckInsTableTableManager(_$AppDatabase db, $MeterCheckInsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeterCheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeterCheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeterCheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> remainingKWh = const Value.absent(),
              }) => MeterCheckInsCompanion(
                id: id,
                date: date,
                remainingKWh: remainingKWh,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required double remainingKWh,
              }) => MeterCheckInsCompanion.insert(
                id: id,
                date: date,
                remainingKWh: remainingKWh,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MeterCheckInsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MeterCheckInsTable,
      MeterCheckIn,
      $$MeterCheckInsTableFilterComposer,
      $$MeterCheckInsTableOrderingComposer,
      $$MeterCheckInsTableAnnotationComposer,
      $$MeterCheckInsTableCreateCompanionBuilder,
      $$MeterCheckInsTableUpdateCompanionBuilder,
      (
        MeterCheckIn,
        BaseReferences<_$AppDatabase, $MeterCheckInsTable, MeterCheckIn>,
      ),
      MeterCheckIn,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TokenPurchasesTableTableManager get tokenPurchases =>
      $$TokenPurchasesTableTableManager(_db, _db.tokenPurchases);
  $$MeterCheckInsTableTableManager get meterCheckIns =>
      $$MeterCheckInsTableTableManager(_db, _db.meterCheckIns);
}
