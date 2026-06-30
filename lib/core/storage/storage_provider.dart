import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/room_sync_service.dart';
import 'onboarding_service.dart';

/// Provider untuk SharedPreferences singleton.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// Provider untuk OnboardingService.
final onboardingServiceProvider = FutureProvider<OnboardingService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return OnboardingService(prefs);
});

/// Provider untuk RoomSyncService.
final roomSyncServiceProvider = FutureProvider<RoomSyncService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return RoomSyncService(prefs);
});
