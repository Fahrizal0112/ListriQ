import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Provider untuk inisialisasi AppDatabase (singleton).
final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  return AppDatabase.create();
});

/// Provider untuk check-in terbaru — invalidated setiap ada data baru.
final latestCheckInProvider = FutureProvider<MeterCheckIn?>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.getLatestCheckIn();
});

/// Provider untuk semua check-in.
final allCheckInsProvider = FutureProvider<List<MeterCheckIn>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.getAllCheckIns();
});

/// Provider untuk semua pembelian token.
final allPurchasesProvider = FutureProvider<List<TokenPurchase>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.getAllPurchases();
});
