import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listriq_app/core/database/app_database.dart';
import 'package:listriq_app/core/database/database_provider.dart';
import 'package:listriq_app/core/prediction/prediction_service.dart';
import 'package:listriq_app/core/storage/onboarding_service.dart';
import 'package:listriq_app/core/storage/storage_provider.dart';

import 'widgets/progress_circle.dart';

/// Dashboard utama.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calibrationAsync = ref.watch(onboardingServiceProvider);
    final lastCheckInAsync = ref.watch(latestCheckInProvider);
    final checkInsAsync = ref.watch(allCheckInsProvider);
    final purchasesAsync = ref.watch(allPurchasesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ ListriQ'),
        centerTitle: true,
      ),
      body: lastCheckInAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildNoData(context, calibrationAsync),
        data: (lastCheckIn) => lastCheckIn == null
            ? _buildNoData(context, calibrationAsync)
            : _buildDashboard(
                context, calibrationAsync, lastCheckIn,
                checkInsAsync, purchasesAsync,
              ),
      ),
    );
  }

  Widget _buildNoData(
    BuildContext context,
    AsyncValue<OnboardingService> calibrationAsync,
  ) {
    final theme = Theme.of(context);

    return Center(
      child: calibrationAsync.when(
        loading: () => const CircularProgressIndicator(),
        error: (e, _) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_chart,
                    size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text('Belum ada data meteran',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                _buildActionButtons(context),
              ],
            ),
          );
        },
        data: (onboarding) {
          final isCalibrated = onboarding.isCalibrated;
          final count = onboarding.checkInCount;

          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_chart,
                    size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text('Belum ada data meteran',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  isCalibrated
                      ? 'Lakukan check-in pertama kamu!'
                      : 'Hari $count dari 7 — tetap semangat! 🔥',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!isCalibrated) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: count / 7,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text('Progress Kalibrasi', style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 24),
                _buildActionButtons(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    AsyncValue<OnboardingService> calibrationAsync,
    MeterCheckIn lastCheckIn,
    AsyncValue<List<MeterCheckIn>> checkInsAsync,
    AsyncValue<List<TokenPurchase>> purchasesAsync,
  ) {
    final checkIns = checkInsAsync.value ?? [];
    final purchases = purchasesAsync.value ?? [];
    final dailyUsage =
        PredictionService.calculateDailyUsage(checkIns, purchases: purchases);
    final effectiveKWh =
        PredictionService.getEffectiveKWh(checkIns, purchases);
    final prediction = dailyUsage != null
        ? PredictionService.predictExhaustionDate(
            currentKWh: effectiveKWh,
            dailyUsage: dailyUsage,
          )
        : null;

    // ── Kalibrasi selesai check ──────────────────────────────
    final calibrationData = calibrationAsync.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 🎉 Kalibrasi selesai banner
          if (calibrationData != null && calibrationData.isCalibrated) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🎉 Kalibrasi selesai! Prediksi sudah akurat. '
                      'Sekarang cukup check-in 1x seminggu.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Lingkaran progres
          const SizedBox(height: 8),
          if (prediction != null)
            ProgressCircle(
              remainingKWh: effectiveKWh,
              remainingDays: prediction.remainingDays,
              urgency: prediction.urgency,
            )
          else ...[
            Icon(Icons.electric_bolt, size: 80,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              '${effectiveKWh.toStringAsFixed(1)} kWh',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const Text('Butuh minimal 2 check-in untuk prediksi'),
          ],
          const SizedBox(height: 8),
          Text(
            'Data terakhir: ${_formatDate(lastCheckIn.date)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          // Status kalibrasi (kalau belum selesai)
          calibrationData != null && !calibrationData.isCalibrated
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      Text(
                        'Kalibrasi: Hari ${calibrationData.checkInCount} dari 7',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: calibrationData.checkInCount / 7,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          // Tombol aksi
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed('/check-in'),
            icon: const Icon(Icons.speed),
            label: const Text(
              '+ Input Check-In Meteran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed('/token-purchase'),
            icon: const Icon(Icons.shopping_cart),
            label: const Text('+ Input Pembelian Token'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed('/room'),
            icon: const Icon(Icons.people),
            label: const Text('Mode Kos / Family Sharing'),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.year}';
}
