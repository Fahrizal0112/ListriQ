import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:listriq_app/core/database/app_database.dart';
import 'package:listriq_app/core/database/database_provider.dart';
import 'package:listriq_app/core/services/background_task_service.dart';
import 'package:listriq_app/core/services/home_widget_service.dart';
import 'package:listriq_app/core/storage/storage_provider.dart';

/// Form check-in manual sisa kWh dari meteran fisik.
class CheckInPage extends ConsumerStatefulWidget {
  const CheckInPage({super.key});

  @override
  ConsumerState<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends ConsumerState<CheckInPage> {
  final _formKey = GlobalKey<FormState>();
  final _kWhController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _kWhController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final kwh = double.parse(_kWhController.text.trim());
      final db = await ref.read(databaseProvider.future);

      await db.insertCheckIn(MeterCheckInsCompanion(
        date: Value(DateTime.now()),
        remainingKWh: Value(kwh),
      ));

      // Increment kalibrasi jika masih dalam masa.
      final onboarding =
          await ref.read(onboardingServiceProvider.future);
      if (!onboarding.isCalibrated) {
        await onboarding.incrementCheckIn();
      }

      // Refresh prediction provider.
      ref.invalidate(databaseProvider);

      // Update home screen widget.
      await HomeWidgetService.updateWidget(db);

      // Reschedule background task ke jam check-in ini.
      await BackgroundTaskService.updateScheduleFromCheckIn();

      // Sync ke room (jika sedang join room).
      final roomSync =
          await ref.read(roomSyncServiceProvider.future);
      await roomSync.syncLastKWh(kwh);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calibration = ref.watch(onboardingServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-In Meteran'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info kalibrasi
              calibration.when(
                data: (svc) {
                  if (!svc.isCalibrated) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Kalibrasi: Hari ${svc.checkInCount + 1} dari 7',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
              // Ikon
              Icon(Icons.speed, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Masukkan Sisa kWh',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Lihat angka di meteran listrik fisik kamu',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Input
              TextFormField(
                controller: _kWhController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Sisa kWh',
                  hintText: 'Contoh: 45.5',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixText: 'kWh',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Harus diisi';
                  final n = double.tryParse(v.trim());
                  if (n == null) return 'Harus angka';
                  if (n <= 0) return 'Harus > 0';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // Tombol simpan
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Simpan Check-In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
