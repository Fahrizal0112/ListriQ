import 'package:listriq_app/core/database/app_database.dart';

/// Hasil prediksi: estimasi kapan token habis.
class PredictionResult {
  final double dailyUsageKWh;   // Laju pemakaian rata-rata (kWh/hari)
  final int remainingDays;      // Estimasi sisa hari
  final DateTime exhaustionDate; // Perkiraan tanggal habis
  final int dataPointsUsed;     // Berapa pasangan data yang dipakai

  const PredictionResult({
    required this.dailyUsageKWh,
    required this.remainingDays,
    required this.exhaustionDate,
    required this.dataPointsUsed,
  });

  /// Indikator warna level urgensi.
  /// Hijau (>7 hari), Kuning (3-7 hari), Merah (<3 hari).
  UrgencyLevel get urgency {
    if (remainingDays > 7) return UrgencyLevel.green;
    if (remainingDays >= 3) return UrgencyLevel.yellow;
    return UrgencyLevel.red;
  }
}

enum UrgencyLevel { green, yellow, red }

/// Layanan prediksi daya listrik berdasarkan data check-in meteran
/// DAN data pembelian token.
class PredictionService {
  /// Menghitung rata-rata pemakaian kWh per hari.
  ///
  /// Logika:
  /// 1. Urutkan check-in berdasarkan tanggal (ascending).
  /// 2. Untuk setiap pasangan berurutan, hitung selisih kWh.
  /// 3. **Jika kWh NAIK** (indikasi pembelian token):
  ///    - Cari semua [TokenPurchase] yang terjadi di antara dua check-in.
  ///    - `pemakaian = (kWh_sebelum + total_pembelian - kWh_sesudah) / hari`
  ///    - Kalau tetap negatif (data aneh), skip saja.
  /// 4. **Jika kWh TURUN** — pemakaian normal:
  ///    - `pemakaian = (kWh_sebelum - kWh_sesudah) / hari`
  /// 5. Weighted average: data ≤3 hari terakhir bobot 3×.
  ///
  /// Returns [dailyUsageKWh] atau `null` jika data tidak mencukupi.
  static double? calculateDailyUsage(
    List<MeterCheckIn> checkIns, {
    List<TokenPurchase> purchases = const [],
  }) {
    if (checkIns.length < 2) return null;

    // Urutkan dari terlama → terbaru.
    final sorted = [...checkIns]
      ..sort((a, b) => a.date.compareTo(b.date));

    // Urutkan purchases juga.
    final sortedPurchases = [...purchases]
      ..sort((a, b) => a.date.compareTo(b.date));

    // Hitung laju harian tiap pasangan berurutan.
    final List<_DailyRate> rates = [];
    for (int i = 0; i < sorted.length - 1; i++) {
      final prev = sorted[i];
      final next = sorted[i + 1];
      // Pakai fractional days — biar check-in beda jam di hari sama tetap valid.
      final dayDiff =
          next.date.difference(prev.date).inMinutes / (24 * 60);

      if (dayDiff <= 0.001) continue; // < 1 menit → anggap sama

      final deltaKWh = prev.remainingKWh - next.remainingKWh;

      if (deltaKWh >= 0) {
        // ── Normal: kWh turun ─────────────────────────────────
        final rate = deltaKWh / dayDiff;
        rates.add(_DailyRate(
          date: next.date,
          dailyKWh: rate,
          daysBetween: dayDiff,
        ));
      } else {
        // ── kWh NAIK: cek apakah ada pembelian token ──────────
        final boughtKWh = _sumPurchasesBetween(
          sortedPurchases,
          prev.date,
          next.date,
        );

        final actualUsage = (prev.remainingKWh + boughtKWh) - next.remainingKWh;

        // Kalau setelah ditambah pembelian tetap negatif → data aneh, skip.
        if (actualUsage < 0) continue;

        final rate = actualUsage / dayDiff;
        rates.add(_DailyRate(
          date: next.date,
          dailyKWh: rate,
          daysBetween: dayDiff,
        ));
      }
    }

    if (rates.isEmpty) return null;

    // ── Weighted Average ──────────────────────────────────────
    // Bobot: data ≤ 3 hari terakhir dapat bobot 3x lipat.
    final now = DateTime.now();
    double totalWeight = 0;
    double weightedSum = 0;

    for (final r in rates) {
      final ageInDays = now.difference(r.date).inDays;
      final weight = ageInDays <= 3 ? 3.0 : 1.0;
      weightedSum += r.dailyKWh * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : null;
  }

  /// Jumlahkan semua kWh pembelian token antara [start] dan [end].
  static double _sumPurchasesBetween(
    List<TokenPurchase> purchases,
    DateTime start,
    DateTime end,
  ) {
    double total = 0;
    for (final p in purchases) {
      if (p.date.isAfter(start) && p.date.isBefore(end) ||
          p.date.isAtSameMomentAs(start) ||
          p.date.isAtSameMomentAs(end)) {
        total += p.kWhAmount;
      }
    }
    return total;
  }

  /// Memprediksi tanggal habis dan sisa hari dari kWh saat ini.
  static PredictionResult predictExhaustionDate({
    required double currentKWh,
    required double dailyUsage,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();

    if (dailyUsage <= 0) {
      return PredictionResult(
        dailyUsageKWh: dailyUsage,
        remainingDays: 999,
        exhaustionDate: now.add(const Duration(days: 999)),
        dataPointsUsed: 0,
      );
    }

    final remainingDays = (currentKWh / dailyUsage).round();
    final exhaustionDate = now.add(Duration(days: remainingDays.clamp(1, 365)));

    return PredictionResult(
      dailyUsageKWh: dailyUsage,
      remainingDays: remainingDays.clamp(0, 365),
      exhaustionDate: exhaustionDate,
      dataPointsUsed: 0,
    );
  }

  /// Alur lengkap: hitung laju → prediksi habis.
  ///
  /// Membaca check-in DAN pembelian token dari database.
  static Future<PredictionResult?> predict(AppDatabase db) async {
    final checkIns = await db.getAllCheckIns();
    if (checkIns.isEmpty) return null;

    final purchases = await db.getAllPurchases();

    final dailyUsage = calculateDailyUsage(checkIns, purchases: purchases);
    if (dailyUsage == null) return null;

    final latest =
        checkIns.reduce((a, b) => a.date.isAfter(b.date) ? a : b);

    final result = predictExhaustionDate(
      currentKWh: latest.remainingKWh,
      dailyUsage: dailyUsage,
    );

    return PredictionResult(
      dailyUsageKWh: result.dailyUsageKWh,
      remainingDays: result.remainingDays,
      exhaustionDate: result.exhaustionDate,
      dataPointsUsed: checkIns.length,
    );
  }
}

/// Data internal untuk perhitungan laju harian.
class _DailyRate {
  final DateTime date;
  final double dailyKWh;
  final double daysBetween; // fractional (pakai inMinutes/1440)

  const _DailyRate({
    required this.date,
    required this.dailyKWh,
    required this.daysBetween,
  });
}
