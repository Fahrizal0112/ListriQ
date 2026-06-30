import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../database/app_database.dart';
import '../prediction/prediction_service.dart';
import 'home_widget_service.dart';
import 'notification_service.dart';

/// Service untuk menjalankan task background via workmanager.
///
/// Jadwal mengikuti jam check-in terakhir user (default 08:00).
class BackgroundTaskService {
  static const _taskName = 'daily_prediction_check';
  static const _uniqueName = 'com.listriq.daily_prediction';

  // SharedPreferences keys
  static const _keyHour = 'bg_check_hour';
  static const _keyMinute = 'bg_check_minute';

  /// Inisialisasi workmanager dan daftarkan task.
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);

    // Baca jam terakhir dari SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_keyHour) ?? 8;
    final minute = prefs.getInt(_keyMinute) ?? 0;

    await _scheduleTask(hour, minute);
  }

  /// Simpan jam check-in terakhir & reschedule background task.
  ///
  /// Dipanggil setiap kali user selesai check-in meteran.
  static Future<void> updateScheduleFromCheckIn() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHour, now.hour);
    await prefs.setInt(_keyMinute, now.minute);

    // Cancel task lama, buat baru dengan jam yang baru.
    await Workmanager().cancelByUniqueName(_uniqueName);
    await _scheduleTask(now.hour, now.minute);
  }

  /// Jadwalkan task harian di [hour]:[minute].
  static Future<void> _scheduleTask(int hour, int minute) async {
    await Workmanager().registerPeriodicTask(
      _uniqueName,
      _taskName,
      frequency: const Duration(hours: 24),
      initialDelay: _nextRunAt(hour, minute),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  /// Hitung delay ke jam [hour]:[minute] berikutnya.
  static Duration _nextRunAt(int hour, int minute) {
    final now = DateTime.now();
    var next =
        DateTime(now.year, now.month, now.day, hour, minute);
    if (now.isAfter(next) || now.isAtSameMomentAs(next)) {
      next = next.add(const Duration(days: 1));
    }
    return next.difference(now);
  }
}

/// Callback yang dipanggil workmanager di background isolate.
/// WAJIB top-level function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await _checkAndNotify();
      return true;
    } catch (e) {
      return false;
    }
  });
}

Future<void> _checkAndNotify() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await AppDatabase.create();
  final checkIns = await db.getAllCheckIns();

  if (checkIns.isEmpty) return;

  final purchases = await db.getAllPurchases();
  final dailyUsage = PredictionService.calculateDailyUsage(checkIns,
      purchases: purchases);
  if (dailyUsage == null) return;

  final effectiveKWh = PredictionService.getEffectiveKWh(checkIns, purchases);
  final latest = checkIns.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  final prediction = PredictionService.predictExhaustionDate(
    currentKWh: effectiveKWh,
    dailyUsage: dailyUsage,
  );

  final lastCheckInAge = DateTime.now().difference(latest.date).inDays;

  if (prediction.remainingDays <= 1) {
    await NotificationService.showPredictionNotification(
      title: '⚠️ Token Segera Habis!',
      body: 'Sisa token diperkirakan ${prediction.remainingDays} hari lagi. '
          'Siap-siap mati lampu!',
    );
  } else if (prediction.remainingDays <= 3) {
    await NotificationService.showPredictionNotification(
      title: '⚡ Token Hampir Habis',
      body: 'Sisa token diperkirakan ${prediction.remainingDays} hari. '
          'Jangan lupa beli token.',
    );
  } else if (lastCheckInAge > 7) {
    await NotificationService.showPredictionNotification(
      title: '🤔 Prediksi Mungkin Meleset',
      body: 'Sudah $lastCheckInAge hari tidak check-in. '
          'Yuk cek meteran lagi agar prediksi akurat!',
    );
  }

  await HomeWidgetService.updateWidget(db);
  await db.close();
}
