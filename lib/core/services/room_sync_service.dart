import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service.dart';

/// Service untuk sinkronisasi data kamar/kos ke Firestore.
///
/// HANYA menyimpan field `lastKWh` di document room (hemat quota Firebase).
/// Data harian tetap di database lokal (Drift).
class RoomSyncService {
  static const _keyCurrentRoom = 'current_room_code';

  final SharedPreferences _prefs;

  RoomSyncService(this._prefs);

  /// Kode room yang sedang aktif, null jika tidak join manapun.
  String? get currentRoomCode => _prefs.getString(_keyCurrentRoom);

  set currentRoomCode(String? code) {
    if (code == null) {
      _prefs.remove(_keyCurrentRoom);
    } else {
      _prefs.setString(_keyCurrentRoom, code);
    }
  }

  /// Kirim update lastKWh ke room (jika user sedang join room).
  Future<void> syncLastKWh(double kwh) async {
    final roomCode = currentRoomCode;
    if (roomCode == null) return;

    await FirebaseService.updateLastKWh(roomCode, kwh);
  }

  /// Pantau update dari room (real-time dari Firestore).
  /// Return stream lastKWh dari room.
  Stream<double?> watchRoomLastKWh(String roomCode) {
    return FirebaseService.firestore
        .collection('rooms')
        .doc(roomCode)
        .snapshots()
        .map((snap) =>
            snap.data()?['lastKWh'] is num
                ? (snap.data()!['lastKWh'] as num).toDouble()
                : null);
  }
}
