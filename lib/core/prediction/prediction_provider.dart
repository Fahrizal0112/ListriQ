import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import 'prediction_service.dart';

/// Provider untuk hasil prediksi terbaru.
/// Di-refresh setiap kali ada check-in baru atau app dibuka.
final predictionProvider = FutureProvider<PredictionResult?>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return PredictionService.predict(db);
});
