import 'package:home_widget/home_widget.dart';

import '../database/app_database.dart';
import '../prediction/prediction_service.dart';

/// Service untuk mengelola Home Screen Widget Android.
///
/// Widget menampilkan: "Sisa: [X] kWh (~[Y] Hari)"
class HomeWidgetService {
  /// Nama widget provider di Android.
  /// Sesuai dengan class di `android/app/src/main/kotlin/.../ListriQWidgetProvider.kt`
  static const _androidName = 'ListriQWidgetProvider';

  /// Save data ke widget storage dan trigger update.
  static Future<void> updateWidget(AppDatabase db) async {
    final checkIns = await db.getAllCheckIns();
    if (checkIns.isEmpty) {
      await HomeWidget.saveWidgetData<String>('kwh', '--');
      await HomeWidget.saveWidgetData<String>('days', '--');
    } else {
      final purchases = await db.getAllPurchases();
      final dailyUsage = PredictionService.calculateDailyUsage(checkIns,
          purchases: purchases);
      final estimatedKWh = dailyUsage != null
          ? PredictionService.getEstimatedCurrentKWh(
              checkIns, purchases, dailyUsage: dailyUsage)
          : PredictionService.getEffectiveKWh(checkIns, purchases);

      final prediction = dailyUsage != null
          ? PredictionService.predictExhaustionDate(
              currentKWh: estimatedKWh,
              dailyUsage: dailyUsage,
            )
          : null;

      await HomeWidget.saveWidgetData<String>(
        'kwh',
        '${estimatedKWh.toStringAsFixed(1)} kWh',
      );
      await HomeWidget.saveWidgetData<String>(
        'days',
        '~${prediction?.remainingDays ?? "?"} Hari',
      );
    }

    // Trigger widget refresh di home screen.
    await HomeWidget.updateWidget(
      androidName: _androidName,
    );
  }
}
