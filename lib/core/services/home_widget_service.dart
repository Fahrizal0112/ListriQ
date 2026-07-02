import 'package:home_widget/home_widget.dart';

import '../database/app_database.dart';
import '../prediction/prediction_service.dart';

/// Service untuk mengelola Home Screen Widget Android.
class HomeWidgetService {
  static const _androidName = 'ListriQWidgetProvider';

  /// Simpan data mentah + trigger widget refresh.
  /// Widget native akan hitung estimasi real-time sendiri.
  static Future<void> updateWidget(AppDatabase db) async {
    final checkIns = await db.getAllCheckIns();
    if (checkIns.isEmpty) {
      await HomeWidget.saveWidgetData<String>('kwh', '--');
      await HomeWidget.saveWidgetData<String>('days', '--');
      await HomeWidget.saveWidgetData<String>('dailyUsage', '');
      await HomeWidget.saveWidgetData<String>('lastKWh', '');
      await HomeWidget.saveWidgetData<String>('lastCheckInMillis', '');
    } else {
      final purchases = await db.getAllPurchases();
      final dailyUsage = PredictionService.calculateDailyUsage(checkIns,
          purchases: purchases);

      final latest =
          checkIns.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
      double extra = 0;
      for (final p in purchases) {
        if (!p.date.isBefore(latest.date)) extra += p.kWhAmount;
      }
      final effectiveKWh = latest.remainingKWh + extra;

      final estimatedKWh = dailyUsage != null
          ? PredictionService.getEstimatedCurrentKWh(
              checkIns, purchases, dailyUsage: dailyUsage)
          : effectiveKWh;

      final prediction = dailyUsage != null
          ? PredictionService.predictExhaustionDate(
              currentKWh: estimatedKWh, dailyUsage: dailyUsage)
          : null;

      // Simpan data mentah untuk native widget
      await HomeWidget.saveWidgetData<String>(
          'kwh', '${estimatedKWh.toStringAsFixed(1)}');

      // Data untuk kalkulasi real-time di native
      await HomeWidget.saveWidgetData<String>(
          'dailyUsage', dailyUsage?.toStringAsFixed(6) ?? '');
      await HomeWidget.saveWidgetData<String>(
          'lastKWh', effectiveKWh.toStringAsFixed(1));
      await HomeWidget.saveWidgetData<String>(
          'lastCheckInMillis', latest.date.millisecondsSinceEpoch.toString());
      await HomeWidget.saveWidgetData<String>(
          'days', prediction != null ? '~${prediction.remainingDays}' : '--');
    }

    await HomeWidget.updateWidget(androidName: _androidName);
  }
}
