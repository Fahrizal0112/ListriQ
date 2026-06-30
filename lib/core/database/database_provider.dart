import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// FutureProvider untuk inisialisasi AppDatabase.
final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  return AppDatabase.create();
});
