import 'package:listriq_app/core/database/app_database.dart';

/// Hasil prediksi: estimasi kapan token habis.
class PredictionResult {
  final double dailyUsageKWh;
  final int remainingDays;
  final DateTime exhaustionDate;
  final int dataPointsUsed;

  const PredictionResult({
    required this.dailyUsageKWh,
    required this.remainingDays,
    required this.exhaustionDate,
    required this.dataPointsUsed,
  });

  UrgencyLevel get urgency {
    if (remainingDays > 7) return UrgencyLevel.green;
    if (remainingDays >= 3) return UrgencyLevel.yellow;
    return UrgencyLevel.red;
  }
}

enum UrgencyLevel { green, yellow, red }

class PredictionService {
  /// Minimal fractional day — cegah rate gila karena test beda detik.
  static const _minDayFraction = 1.0 / 24; // ~1 jam

  // ── calculateDailyUsage ──────────────────────────────────────

  static double? calculateDailyUsage(
    List<MeterCheckIn> checkIns, {
    List<TokenPurchase> purchases = const [],
  }) {
    if (checkIns.length < 2) return null;

    final sorted = [...checkIns]
      ..sort((a, b) => a.date.compareTo(b.date));
    final sortedPurchases = [...purchases]
      ..sort((a, b) => a.date.compareTo(b.date));

    final List<_DailyRate> rates = [];
    for (int i = 0; i < sorted.length - 1; i++) {
      final prev = sorted[i];
      final next = sorted[i + 1];
      var dayDiff =
          next.date.difference(prev.date).inMilliseconds /
              (24.0 * 60 * 60 * 1000);

      if (dayDiff < _minDayFraction) dayDiff = _minDayFraction;

      final deltaKWh = prev.remainingKWh - next.remainingKWh;

      if (deltaKWh >= 0) {
        rates.add(_DailyRate(date: next.date, dailyKWh: deltaKWh / dayDiff,
            daysBetween: dayDiff));
      } else {
        final bought = _sumPurchasesBetween(sortedPurchases, prev.date, next.date);
        final actual = (prev.remainingKWh + bought) - next.remainingKWh;
        if (actual < 0) continue;
        rates.add(_DailyRate(date: next.date, dailyKWh: actual / dayDiff,
            daysBetween: dayDiff));
      }
    }

    if (rates.isEmpty) return null;

    final now = DateTime.now();
    double totalW = 0, sum = 0;
    for (final r in rates) {
      final age = now.difference(r.date).inDays;
      final w = age <= 3 ? 3.0 : 1.0;
      sum += r.dailyKWh * w;
      totalW += w;
    }
    return totalW > 0 ? sum / totalW : null;
  }

  static double _sumPurchasesBetween(
      List<TokenPurchase> purchases, DateTime start, DateTime end) {
    double total = 0;
    for (final p in purchases) {
      if (!p.date.isBefore(start) && !p.date.isAfter(end)) total += p.kWhAmount;
    }
    return total;
  }

  // ── Effective kWh (check-in + pembelian setelahnya) ─────────

  /// kWh efektif saat ini = kWh check-in terakhir + semua pembelian token
  /// yang terjadi SETELAH check-in terakhir.
  static double getEffectiveKWh(
    List<MeterCheckIn> checkIns,
    List<TokenPurchase> purchases,
  ) {
    if (checkIns.isEmpty) return 0;
    final latest =
        checkIns.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    double extra = 0;
    for (final p in purchases) {
      if (!p.date.isBefore(latest.date)) extra += p.kWhAmount;
    }
    return latest.remainingKWh + extra;
  }

  // ── predict ──────────────────────────────────────────────────

  static PredictionResult predictExhaustionDate({
    required double currentKWh,
    required double dailyUsage,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    if (dailyUsage <= 0) {
      return PredictionResult(
        dailyUsageKWh: dailyUsage, remainingDays: 999,
        exhaustionDate: now.add(const Duration(days: 999)),
        dataPointsUsed: 0,
      );
    }
    final rem = (currentKWh / dailyUsage).round();
    final exhaustion = now.add(Duration(days: rem.clamp(1, 365)));
    return PredictionResult(
      dailyUsageKWh: dailyUsage,
      remainingDays: rem.clamp(0, 365),
      exhaustionDate: exhaustion,
      dataPointsUsed: 0,
    );
  }

  static Future<PredictionResult?> predict(AppDatabase db) async {
    final checkIns = await db.getAllCheckIns();
    if (checkIns.isEmpty) return null;
    final purchases = await db.getAllPurchases();
    final dailyUsage = calculateDailyUsage(checkIns, purchases: purchases);
    if (dailyUsage == null) return null;
    final effectiveKWh = getEffectiveKWh(checkIns, purchases);
    final result = predictExhaustionDate(
        currentKWh: effectiveKWh, dailyUsage: dailyUsage);
    return PredictionResult(
      dailyUsageKWh: result.dailyUsageKWh,
      remainingDays: result.remainingDays,
      exhaustionDate: result.exhaustionDate,
      dataPointsUsed: checkIns.length,
    );
  }
}

class _DailyRate {
  final DateTime date;
  final double dailyKWh;
  final double daysBetween;
  const _DailyRate({
    required this.date,
    required this.dailyKWh,
    required this.daysBetween,
  });
}
