import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:listriq_app/core/database/app_database.dart';
import 'package:listriq_app/core/database/database_provider.dart';
import 'package:listriq_app/core/storage/storage_provider.dart';
import 'package:listriq_app/main.dart';

/// Test wrapper: bungkus widget dengan ProviderScope + overrides.
Widget testApp() {
  // Gunakan in-memory database untuk test.
  final db = AppDatabase.inMemory();

  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(AsyncValue.data(db)),
      sharedPreferencesProvider.overrideWithValue(
        AsyncValue.data(SharedPreferencesMock()),
      ),
    ],
    child: const ListriQApp(),
  );
}

void main() {
  testWidgets('App starts with onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Harusnya route ke onboarding (belum onboarded).
    expect(find.text('Selamat Datang di ListriQ!'), findsOneWidget);
  });
}

/// Mock SharedPreferences sederhana untuk testing.
class SharedPreferencesMock implements SharedPreferences {
  final Map<String, Object> _data = {};

  @override
  Set<String> getKeys() => _data.keys.toSet();

  @override
  Object? get(String key) => _data[key];

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  int? getInt(String key) => _data[key] as int?;

  @override
  double? getDouble(String key) => _data[key] as double?;

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  bool containsKey(String key) => _data.containsKey(key);

  @override
  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _data.clear();
    return true;
  }

  @override
  Future<void> reload() async {}

  @override
  Future<bool> commit() async => true;

  @override
  List<String>? getStringList(String key) =>
      (_data[key] as List<dynamic>?)?.cast<String>();

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = value;
    return true;
  }
}
