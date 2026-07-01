import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'core/services/background_task_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/storage/storage_provider.dart';
import 'features/check_in/check_in_list_page.dart';
import 'features/check_in/check_in_page.dart';
import 'features/check_in/token_purchase_page.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/room/room_management_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi database & SharedPreferences (wajib).
  final db = await AppDatabase.create();
  final prefs = await SharedPreferences.getInstance();

  // Firebase, notifikasi, workmanager → fire-and-forget.
  // Jangan block runApp() kalau gagal.
  _initServices();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(AsyncValue.data(db)),
        sharedPreferencesProvider.overrideWithValue(AsyncValue.data(prefs)),
      ],
      child: const ListriQApp(),
    ),
  );
}

/// Inisialisasi service opsional — tidak block app.
void _initServices() {
  _initFirebase();
  NotificationService.init().onError((_, __) => _noop());
  BackgroundTaskService.init().onError((_, __) => _noop());
}

Future<void> _initFirebase() async {
  try {
    await FirebaseService.init();
    await FirebaseService.signInAnonymously();
  } catch (_) {
    // Firebase opsional — app tetap jalan tanpa Firebase.
  }
}

/// Placeholder untuk error handler.
bool _noop() => true;

class ListriQApp extends ConsumerWidget {
  const ListriQApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'ListriQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const _SplashRouter(),
      routes: {
        '/onboarding': (context) => const OnboardingPage(),
        '/home': (context) => const HomeScreen(),
        '/check-in': (context) => const CheckInPage(),
        '/check-in-list': (context) => const CheckInListPage(),
        '/token-purchase': (context) => const TokenPurchasePage(),
        '/room': (context) => const RoomManagementPage(),
      },
    );
  }
}

/// Splash screen — tentukan rute awal (onboarding / home).
class _SplashRouter extends ConsumerWidget {
  const _SplashRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingServiceProvider);

    return onboardingAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) {
        // Fallback: kalau SharedPreferences error, langsung ke home.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/home');
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      data: (onboarding) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!onboarding.isOnboarded) {
            Navigator.of(context).pushReplacementNamed('/onboarding');
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
