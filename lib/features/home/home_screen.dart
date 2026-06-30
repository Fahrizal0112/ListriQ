import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listriq_app/core/database/app_database.dart';
import 'package:listriq_app/core/database/database_provider.dart';
import 'package:listriq_app/core/prediction/prediction_service.dart';
import 'package:listriq_app/core/storage/onboarding_service.dart';
import 'package:listriq_app/core/storage/storage_provider.dart';

import 'widgets/progress_circle.dart';

/// Dashboard utama setelah onboarding/kalibrasi.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(databaseProvider);
    final lastCheckInAsync = dbAsync.when(
      data: (db) => ref.watch(_latestCheckInProvider(db)),
      loading: () => const AsyncValue.loading(),
      error: (e, _) => AsyncValue.error(e, StackTrace.empty),
    );
    final calibrationAsync = ref.watch(onboardingServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ ListriQ'),
        centerTitle: true,
      ),
      body: Center(
        child: dbAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (db) => lastCheckInAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => _buildNoData(context, ref, calibrationAsync),
            data: (lastCheckIn) => lastCheckIn != null
                ? _buildDashboard(
                    context, ref, db, lastCheckIn, calibrationAsync)
                : _buildNoData(context, ref, calibrationAsync),
          ),
        ),
      ),
    );
  }

  Widget _buildNoData(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<OnboardingService> calibrationAsync,
  ) {
    return calibrationAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => const Text('Error loading status'),
      data: (onboarding) {
        final isCalibrated = onboarding.isCalibrated;
        final count = onboarding.checkInCount;
        final theme = Theme.of(context);

        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_chart,
                  size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Belum ada data meteran',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
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
                Text(
                  'Progress Kalibrasi',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
              _buildActionButtons(context, ref),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    AppDatabase db,
    MeterCheckIn lastCheckIn,
    AsyncValue<OnboardingService> calibrationAsync,
  ) {
    // Hitung prediksi real-time (dengan data pembelian token).
    final checkIns = ref.watch(_allCheckInsProvider(db)).value ?? [];
    final purchases = ref.watch(_allPurchasesProvider(db)).value ?? [];
    final dailyUsage =
        PredictionService.calculateDailyUsage(checkIns, purchases: purchases);
    final prediction = dailyUsage != null
        ? PredictionService.predictExhaustionDate(
            currentKWh: lastCheckIn.remainingKWh,
            dailyUsage: dailyUsage,
          )
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Lingkaran progres
          if (prediction != null)
            ProgressCircle(
              remainingKWh: lastCheckIn.remainingKWh,
              remainingDays: prediction.remainingDays,
              urgency: prediction.urgency,
            )
          else
            ProgressCircle(
              remainingKWh: lastCheckIn.remainingKWh,
              remainingDays: 0,
              urgency: UrgencyLevel.green,
            ),
          const SizedBox(height: 8),
          Text(
            'Data terakhir: ${_formatDate(lastCheckIn.date)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          // Status kalibrasi (jika masih dalam masa)
          calibrationAsync.when(
            data: (onboarding) {
              if (!onboarding.isCalibrated) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      Text(
                        'Kalibrasi: Hari ${onboarding.checkInCount} dari 7',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: onboarding.checkInCount / 7,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            error: (_, __) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
          // Tombol aksi
          _buildActionButtons(context, ref),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
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

/// Provider untuk check-in terbaru.
final _latestCheckInProvider = FutureProvider.family<MeterCheckIn?, AppDatabase>(
  (ref, db) => db.getLatestCheckIn(),
);

/// Provider untuk semua check-in.
final _allCheckInsProvider =
    FutureProvider.family<List<MeterCheckIn>, AppDatabase>(
  (ref, db) => db.getAllCheckIns(),
);

/// Provider untuk semua pembelian token.
final _allPurchasesProvider =
    FutureProvider.family<List<TokenPurchase>, AppDatabase>(
  (ref, db) => db.getAllPurchases(),
);
