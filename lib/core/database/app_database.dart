import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ─── Tabel TokenPurchases ──────────────────────────────────────────
// Mencatat setiap pembelian token listrik.
class TokenPurchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get kWhAmount => real()();
}

// ─── Tabel MeterCheckIns ───────────────────────────────────────────
// Mencatat check-in manual sisa kWh dari meteran fisik.
class MeterCheckIns extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get remainingKWh => real()();
}

// ─── Database ──────────────────────────────────────────────────────
@DriftDatabase(tables: [TokenPurchases, MeterCheckIns])
class AppDatabase extends _$AppDatabase {
  AppDatabase._(super.executor);

  /// Factory: buat instance database di folder aplikasi lokal.
  static Future<AppDatabase> create() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'listriq.db'));
    return AppDatabase._(NativeDatabase(file));
  }

  /// Digunakan untuk test (in-memory database).
  AppDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  // ─── DAO: TokenPurchases ─────────────────────────────────────

  /// Insert pembelian token baru.
  Future<int> insertPurchase(TokenPurchasesCompanion entry) =>
      into(tokenPurchases).insert(entry);

  /// Ambil semua pembelian token, terbaru dulu.
  Future<List<TokenPurchase>> getAllPurchases() =>
      (select(tokenPurchases)..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  /// Stream semua pembelian token.
  Stream<List<TokenPurchase>> watchAllPurchases() =>
      (select(tokenPurchases)..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  /// Hapus pembelian token berdasarkan ID.
  Future<int> deletePurchase(int id) =>
      (delete(tokenPurchases)..where((t) => t.id.equals(id))).go();

  // ─── DAO: MeterCheckIns ─────────────────────────────────────

  /// Insert check-in meteran baru.
  Future<int> insertCheckIn(MeterCheckInsCompanion entry) =>
      into(meterCheckIns).insert(entry);

  /// Ambil semua check-in, terbaru dulu.
  Future<List<MeterCheckIn>> getAllCheckIns() =>
      (select(meterCheckIns)..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  /// Stream semua check-in.
  Stream<List<MeterCheckIn>> watchAllCheckIns() =>
      (select(meterCheckIns)..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  /// Ambil check-in terakhir (paling baru).
  Future<MeterCheckIn?> getLatestCheckIn() =>
      (select(meterCheckIns)
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(1))
          .getSingleOrNull();

  /// Ambil check-in dalam rentang tanggal.
  Future<List<MeterCheckIn>> getCheckInsBetween(
          DateTime start, DateTime end) =>
      (select(meterCheckIns)
            ..where((t) => t.date.isBetweenValues(start, end))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .get();

  /// Update check-in berdasarkan ID.
  Future<bool> updateCheckIn(MeterCheckIn entry) =>
      update(meterCheckIns).replace(entry);

  /// Hapus check-in berdasarkan ID.
  Future<int> deleteCheckIn(int id) =>
      (delete(meterCheckIns)..where((t) => t.id.equals(id))).go();
}
