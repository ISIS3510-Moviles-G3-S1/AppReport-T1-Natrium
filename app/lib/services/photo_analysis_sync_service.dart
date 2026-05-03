import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../core/photo_quality_vision_service.dart';
import 'pending_photo_analysis_storage.dart';

class PhotoAnalysisSyncService {
  final PendingPhotoAnalysisStorage _storage = PendingPhotoAnalysisStorage();
  final VisionPhotoQualityService _visionService = VisionPhotoQualityService();

  Future<void> syncPending() async {
    final connectivity = Connectivity();
    final connectivityResults = await connectivity.checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
    if (!isOnline) return;

    final pending = await _storage.getAllPending();
    for (final item in pending) {
      try {
        // Re-analizar con Vision API
        final xfile = XFile(item.filePath);
        final result = await _visionService.analyzePhoto(xfile);
        // Aquí puedes actualizar el resultado en backend o local
        await _storage.markAsSynced(item.id!);
        // Opcional: eliminar el registro si ya no es necesario
        // await _storage.delete(item.id!);
      } catch (e) {
        // Si falla, dejar pendiente para el próximo intento
      }
    }
  }
}
