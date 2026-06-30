import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listriq_app/core/storage/storage_provider.dart';

/// Halaman onboarding yang menjelaskan cara kerja aplikasi.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _currentStep = 0;

  static const _steps = [
    _Step(
      icon: Icons.electric_bolt,
      title: 'Selamat Datang di ListriQ!',
      description:
          'Aplikasi pintar untuk memprediksi kapan token listrik kamu habis.\n\n'
          'Tidak perlu lagi panik mati lampu mendadak!',
    ),
    _Step(
      icon: Icons.edit_calendar,
      title: 'Kalibrasi 7 Hari',
      description:
          'Selama 7 hari pertama, kamu perlu input sisa kWh meteran SETIAP HARI.\n\n'
          'Ini penting agar prediksi jadi akurat sesuai pemakaian kamu.',
    ),
    _Step(
      icon: Icons.checklist,
      title: 'Check-In Mingguan',
      description:
          'Setelah kalibrasi selesai, kamu cukup check-in minimal 1x seminggu.\n\n'
          'ListriQ akan kirim notifikasi saat token hampir habis!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isLast = _currentStep == _steps.length - 1;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Ikon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, size: 56, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 40),
              // Judul
              Text(
                step.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Deskripsi
              Text(
                step.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              // Dot indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (i) => Container(
                    width: i == _currentStep ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _currentStep
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Tombol
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    if (isLast) {
                      // Tandai onboarding selesai + mulai kalibrasi
                      final onboarding =
                          await ref.read(onboardingServiceProvider.future);
                      await onboarding.completeOnboarding();
                      await onboarding.startCalibration();
                      if (mounted) {
                        Navigator.of(context).pushReplacementNamed('/home');
                      }
                    } else {
                      setState(() => _currentStep++);
                    }
                  },
                  child: Text(isLast ? 'Mulai Kalibrasi' : 'Lanjut'),
                ),
              ),
              if (!isLast) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    final onboarding =
                        await ref.read(onboardingServiceProvider.future);
                    await onboarding.completeOnboarding();
                    await onboarding.startCalibration();
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  },
                  child: const Text('Lewati'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Step {
  final IconData icon;
  final String title;
  final String description;
  const _Step({
    required this.icon,
    required this.title,
    required this.description,
  });
}
