import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Service untuk Firebase: Auth Anonymous + Firestore (Mode Kos).
class FirebaseService {
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;

  /// Inisialisasi Firebase dengan opsi spesifik platform.
  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  /// Login anonymous (tidak perlu email/password).
  static Future<User> signInAnonymously() async {
    final result = await auth.signInAnonymously();
    return result.user!;
  }

  /// Sign out.
  static Future<void> signOut() => auth.signOut();

  // ─── Rooms ──────────────────────────────────────────────────────

  /// Buat room baru, return kode invite (document ID).
  static Future<String> createRoom(String roomName) async {
    final doc = await firestore.collection('rooms').add({
      'name': roomName,
      'createdBy': auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'lastKWh': null,
      'lastUpdatedBy': null,
      'lastUpdatedAt': null,
    });
    return doc.id; // kode invite = document ID
  }

  /// Gabung ke room dengan kode invite.
  static Future<void> joinRoom(String inviteCode) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) throw Exception('Belum login');

    // Verifikasi room exists.
    final roomDoc =
        await firestore.collection('rooms').doc(inviteCode).get();
    if (!roomDoc.exists) throw Exception('Room tidak ditemukan');

    // Daftarkan member.
    await firestore.collection('rooms').doc(inviteCode).collection('members')
        .doc(userId)
        .set({'joinedAt': FieldValue.serverTimestamp()});
  }

  /// Keluar dari room.
  static Future<void> leaveRoom(String inviteCode) async {
    final userId = auth.currentUser?.uid;
    await firestore
        .collection('rooms')
        .doc(inviteCode)
        .collection('members')
        .doc(userId)
        .delete();
  }

  /// Update lastKWh setelah check-in / beli token.
  static Future<void> updateLastKWh(
    String inviteCode,
    double kwh,
  ) async {
    final userId = auth.currentUser?.uid;
    await firestore.collection('rooms').doc(inviteCode).update({
      'lastKWh': kwh,
      'lastUpdatedBy': userId,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream room yang diikuti user saat ini.
  static Stream<QuerySnapshot> getUserRooms() {
    final userId = auth.currentUser?.uid;
    return firestore
        .collectionGroup('members')
        .where(FieldPath.documentId, isEqualTo: userId)
        .snapshots();
  }

  /// Stream detail sebuah room.
  static Stream<DocumentSnapshot> watchRoom(String roomId) {
    return firestore.collection('rooms').doc(roomId).snapshots();
  }
}
