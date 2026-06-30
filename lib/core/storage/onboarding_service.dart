import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola status onboarding & kalibrasi melalui SharedPreferences.
class OnboardingService {
  static const _keyIsOnboarded = 'is_onboarded';   // Sudah lihat onboarding
  static const _keyIsCalibrated = 'is_calibrated'; // Selesai 7 hari kalibrasi
  static const _keyCalibrationStart = 'calibration_start'; // Tanggal mulai
  static const _keyCheckInCount = 'check_in_count'; // Jumlah check-in saat ini

  final SharedPreferences _prefs;

  OnboardingService(this._prefs);

  // ── Onboarding ──────────────────────────────────────────────
  bool get isOnboarded => _prefs.getBool(_keyIsOnboarded) ?? false;
  Future<void> completeOnboarding() => _prefs.setBool(_keyIsOnboarded, true);

  // ── Kalibrasi ───────────────────────────────────────────────
  bool get isCalibrated => _prefs.getBool(_keyIsCalibrated) ?? false;

  DateTime? get calibrationStart {
    final ms = _prefs.getInt(_keyCalibrationStart);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  int get checkInCount => _prefs.getInt(_keyCheckInCount) ?? 0;

  /// Panggil saat user mulai kalibrasi.
  Future<void> startCalibration() async {
    await _prefs.setInt(
        _keyCalibrationStart, DateTime.now().millisecondsSinceEpoch);
    await _prefs.setInt(_keyCheckInCount, 0);
  }

  /// Panggil setiap kali user check-in selama kalibrasi.
  Future<void> incrementCheckIn() async {
    final count = checkInCount + 1;
    await _prefs.setInt(_keyCheckInCount, count);
    if (count >= 7) {
      await _prefs.setBool(_keyIsCalibrated, true);
    }
  }

  /// Reset (untuk testing).
  Future<void> reset() async {
    await _prefs.remove(_keyIsOnboarded);
    await _prefs.remove(_keyIsCalibrated);
    await _prefs.remove(_keyCalibrationStart);
    await _prefs.remove(_keyCheckInCount);
  }
}
