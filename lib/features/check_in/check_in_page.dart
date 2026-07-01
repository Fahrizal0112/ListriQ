import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import 'package:listriq_app/core/database/app_database.dart';
import 'package:listriq_app/core/database/database_provider.dart';
import 'package:listriq_app/core/services/background_task_service.dart';
import 'package:listriq_app/core/services/home_widget_service.dart';
import 'package:listriq_app/core/storage/storage_provider.dart';

/// Form check-in manual — bisa tambah baru atau edit data lama.
///
/// Kirim [MeterCheckIn] sebagai route argument untuk edit mode.
class CheckInPage extends ConsumerStatefulWidget {
  const CheckInPage({super.key});

  @override
  ConsumerState<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends ConsumerState<CheckInPage> {
  final _formKey = GlobalKey<FormState>();
  final _kWhController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;

  /// Null = tambah baru, not null = edit.
  MeterCheckIn? _editTarget;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cek argumen — kalau ada MeterCheckIn berarti edit mode.
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is MeterCheckIn) {
        setState(() {
          _editTarget = arg;
          _kWhController.text = arg.remainingKWh.toStringAsFixed(1);
          _selectedDate = arg.date;
          _selectedTime = TimeOfDay.fromDateTime(arg.date);
        });
      }
    });
  }

  @override
  void dispose() {
    _kWhController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _selectedTime);
    if (t != null) setState(() => _selectedTime = t);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final kwh = double.parse(_kWhController.text.trim());
      final db = await ref.read(databaseProvider.future);

      final date = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (_editTarget != null) {
        // ── EDIT: update existing ─────────────────────────
        await db.updateCheckIn(
          MeterCheckIn(
            id: _editTarget!.id,
            date: date,
            remainingKWh: kwh,
          ),
        );
      } else {
        // ── TAMBAH BARU ───────────────────────────────────
        await db.insertCheckIn(MeterCheckInsCompanion(
          date: Value(date),
          remainingKWh: Value(kwh),
        ));

        // Increment kalibrasi jika masih dalam masa.
        final onboarding =
            await ref.read(onboardingServiceProvider.future);
        if (!onboarding.isCalibrated) {
          await onboarding.incrementCheckIn();
        }

        // Reschedule background task ke jam check-in ini.
        await BackgroundTaskService.updateScheduleFromCheckIn();
      }

      // Invalidate semua provider biar UI refresh.
      ref.invalidate(sharedPreferencesProvider);
      ref.invalidate(onboardingServiceProvider);
      ref.invalidate(latestCheckInProvider);
      ref.invalidate(allCheckInsProvider);
      ref.invalidate(allPurchasesProvider);

      // Update home screen widget.
      await HomeWidgetService.updateWidget(db);

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

  Future<void> _delete() async {
    if (_editTarget == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Check-In'),
        content: Text(
          'Yakin hapus check-in ${_editTarget!.remainingKWh.toStringAsFixed(1)} kWh '
          '(${DateFormat('dd/MM/yyyy HH:mm').format(_editTarget!.date)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final db = await ref.read(databaseProvider.future);
    await db.deleteCheckIn(_editTarget!.id);
    ref.invalidate(allCheckInsProvider);
    ref.invalidate(latestCheckInProvider);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = _editTarget != null;
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final timeStr = _selectedTime.format(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Check-In' : 'Check-In Meteran'),
        centerTitle: true,
        actions: isEdit
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _delete,
                  tooltip: 'Hapus',
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.speed, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                isEdit ? 'Edit Sisa kWh' : 'Masukkan Sisa kWh',
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
              // Input kWh
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
              const SizedBox(height: 20),
              // Tanggal & jam
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(dateStr),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(timeStr),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
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
                      : Text(
                          isEdit ? 'Simpan Perubahan' : 'Simpan Check-In',
                          style: const TextStyle(
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
