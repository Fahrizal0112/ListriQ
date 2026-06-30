import 'package:flutter_test/flutter_test.dart';
import 'package:listriq_app/core/database/app_database.dart';
import 'package:listriq_app/core/prediction/prediction_service.dart';

void main() {
  group('calculateDailyUsage', () {
    test('returns null when less than 2 check-ins', () {
      final result = PredictionService.calculateDailyUsage([]);
      expect(result, isNull);

      final single = [_checkIn(10.0, 0)];
      expect(PredictionService.calculateDailyUsage(single), isNull);
    });

    test('calculates daily rate from consecutive check-ins', () {
      // 3 hari lalu: 10 kWh, hari ini: 7 kWh → (10-7)/3 = 1 kWh/hari
      final data = [
        _checkIn(10.0, 3),
        _checkIn(7.0, 0),
      ];
      final rate = PredictionService.calculateDailyUsage(data);
      expect(rate, isNotNull);
      expect(rate!, closeTo(1.0, 0.01));
    });

    test('kWh naik tanpa pembelian token → pasangan di-skip', () {
      // 4 hari lalu: 5 kWh
      // 2 hari lalu: 15 kWh (naik! tapi TIDAK ada pembelian → skip pasangan 5→15)
      // Hari ini: 10 kWh
      // Pasangan valid: (15→10) / 2 hari = 2.5 kWh/hari
      final data = [
        _checkIn(5.0, 4),
        _checkIn(15.0, 2),
        _checkIn(10.0, 0),
      ];
      // Tanpa purchases → 5→15 di-skip.
      final rate = PredictionService.calculateDailyUsage(data);
      expect(rate, isNotNull);
      expect(rate!, closeTo(2.5, 0.01));
    });

    test('kWh naik DENGAN pembelian token → hitung akurat', () {
      // Skenario: user beli token 20 kWh di antara check-in.
      //
      // Hari 4 (Senin):     check-in 5 kWh
      // Hari 3 (Selasa):    BELI TOKEN 20 kWh  ← TokenPurchase
      // Hari 2 (Rabu):      check-in 22 kWh (ada pemakaian)
      // Hari 0 (Kamis):     check-in 18 kWh
      //
      // Pasangan 1 (Senin→Rabu):
      //   kWh naik: 5 → 22. Ada pembelian 20 kWh di antaranya.
      //   Pemakaian = (5 + 20 - 22) / 2 hari = 3 / 2 = 1.5 kWh/hari ✓
      //
      // Pasangan 2 (Rabu→Kamis):
      //   kWh turun: 22 → 18 dalam 2 hari = 2.0 kWh/hari
      //
      // Weighted: keduanya ≤3 hari → weight 3: (1.5*3 + 2.0*3) / 6 = 1.75

      final data = [
        _checkIn(5.0, 4),
        _checkIn(22.0, 2),
        _checkIn(18.0, 0),
      ];
      final purchases = [
        _purchase(20.0, 3), // Selasa: beli 20 kWh
      ];
      final rate =
          PredictionService.calculateDailyUsage(data, purchases: purchases);
      expect(rate, isNotNull);
      expect(rate!, closeTo(1.75, 0.01));
    });

    test('beli token pas di hari check-in → tetap akurat', () {
      // Hari 2: check-in 8 kWh, lalu BELI TOKEN 10 kWh
      // Hari 0: check-in 14 kWh
      //
      // kWh naik: 8 → 14. Ada pembelian 10 kWh.
      // Pemakaian = (8 + 10 - 14) / 2 hari = 4/2 = 2.0 kWh/hari
      final data = [
        _checkIn(8.0, 2),
        _checkIn(14.0, 0),
      ];
      final purchases = [
        _purchase(10.0, 2), // beli 10 kWh di hari yang sama dengan check-in
      ];
      final rate =
          PredictionService.calculateDailyUsage(data, purchases: purchases);
      expect(rate, isNotNull);
      expect(rate!, closeTo(2.0, 0.01));
    });

    test('weighted average: both recent rates get weight 3x', () {
      // 4 hari lalu: 20, 2 hari lalu: 18, hari ini: 14
      // Rate 1 (20→18): 1.0 kWh/hari, age=2 → weight 3
      // Rate 2 (18→14): 2.0 kWh/hari, age=0 → weight 3
      // Weighted avg: (1.0*3 + 2.0*3) / 6 = 1.5 kWh/hari
      final data = [
        _checkIn(20.0, 4),
        _checkIn(18.0, 2),
        _checkIn(14.0, 0),
      ];
      final rate = PredictionService.calculateDailyUsage(data);
      expect(rate, isNotNull);
      expect(rate!, closeTo(1.5, 0.01));
    });
  });

  group('predictExhaustionDate', () {
    test('predicts correct remaining days', () {
      final result = PredictionService.predictExhaustionDate(
        currentKWh: 10.0,
        dailyUsage: 2.5,
        referenceDate: DateTime(2026, 7, 1),
      );
      expect(result.remainingDays, 4); // 10 / 2.5 = 4
      expect(result.exhaustionDate, DateTime(2026, 7, 5));
    });

    test('urgency levels', () {
      expect(
        PredictionService.predictExhaustionDate(
          currentKWh: 40,
          dailyUsage: 2,
          referenceDate: DateTime(2026, 7, 1),
        ).urgency,
        UrgencyLevel.green,
      );
      expect(
        PredictionService.predictExhaustionDate(
          currentKWh: 10,
          dailyUsage: 2,
          referenceDate: DateTime(2026, 7, 1),
        ).urgency,
        UrgencyLevel.yellow,
      );
      expect(
        PredictionService.predictExhaustionDate(
          currentKWh: 3,
          dailyUsage: 2,
          referenceDate: DateTime(2026, 7, 1),
        ).urgency,
        UrgencyLevel.red,
      );
    });

    test('handles zero usage gracefully', () {
      final result = PredictionService.predictExhaustionDate(
        currentKWh: 10.0,
        dailyUsage: 0,
        referenceDate: DateTime(2026, 7, 1),
      );
      expect(result.remainingDays, 999);
    });
  });
}

/// Helper: buat check-in dummy di [daysAgo] hari lalu.
MeterCheckIn _checkIn(double kwh, int daysAgo) {
  final date = DateTime.now().subtract(Duration(days: daysAgo));
  return MeterCheckIn(id: 0, date: date, remainingKWh: kwh);
}

/// Helper: buat pembelian token dummy di [daysAgo] hari lalu.
TokenPurchase _purchase(double kwh, int daysAgo) {
  final date = DateTime.now().subtract(Duration(days: daysAgo));
  return TokenPurchase(id: 0, date: date, kWhAmount: kwh);
}
