import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Servicio de almacenamiento para gestionar subida de evidencias e imágenes en Firebase Storage
class StorageService {
  StorageService({FirebaseStorage? storage, ImagePicker? picker})
      : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  final FirebaseStorage _storage;
  final ImagePicker _picker;

  /// Permite seleccionar una imagen desde la cámara
  Future<XFile?> pickImageFromCamera() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );
  }

  /// Permite seleccionar una imagen desde la galería
  Future<XFile?> pickImageFromGallery() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );
  }

  /// Permite seleccionar múltiples imágenes de evidencia desde la galería
  Future<List<XFile>> pickMultiImages() async {
    return await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );
  }

  /// Sube la foto seleccionada (desde la cámara o galería) a Firebase Storage
  /// dentro de la ruta organizada `report_images/{timestamp}.jpg` (o con el nombre indicado),
  /// retornando la `downloadUrl` pública.
  Future<String> uploadReportImage({
    required XFile file,
    String? customFileName,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = customFileName ?? '$timestamp.jpg';
    final ref = _storage.ref().child('report_images').child(fileName);

    final metadata = SettableMetadata(
      contentType: file.mimeType ?? 'image/jpeg',
      customMetadata: {
        'uploadedAt': DateTime.now().toIso8601String(),
        'originalName': file.name,
      },
    );

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final uploadTask = await ref.putData(bytes, metadata);
      return await uploadTask.ref.getDownloadURL();
    } else {
      final ioFile = File(file.path);
      final uploadTask = await ref.putFile(ioFile, metadata);
      return await uploadTask.ref.getDownloadURL();
    }
  }

  /// Sube un archivo XFile (cámara o galería) a Firebase Storage y retorna la URL pública de descarga
  Future<String> uploadEvidenceImage({
    required XFile file,
    required String reportId,
    String? customFileName,
  }) async {
    final fileName = customFileName ??
        'evidence_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = _storage.ref().child('reports').child(reportId).child(fileName);

    SettableMetadata metadata = SettableMetadata(
      contentType: file.mimeType ?? 'image/jpeg',
      customMetadata: {
        'uploadedAt': DateTime.now().toIso8601String(),
        'reportId': reportId,
      },
    );

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final uploadTask = await ref.putData(bytes, metadata);
      return await uploadTask.ref.getDownloadURL();
    } else {
      final ioFile = File(file.path);
      final uploadTask = await ref.putFile(ioFile, metadata);
      return await uploadTask.ref.getDownloadURL();
    }
  }

  /// Sube bytes de imagen en memoria (compatible con Web y tests)
  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String storagePath,
    String contentType = 'image/jpeg',
  }) async {
    final ref = _storage.ref().child(storagePath);
    final metadata = SettableMetadata(contentType: contentType);
    final uploadTask = await ref.putData(bytes, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Sube una lista de evidencias fotográficas para un reporte específico y retorna todas las URLs
  Future<List<String>> uploadMultipleEvidences({
    required List<XFile> files,
    required String reportId,
  }) async {
    final List<String> downloadUrls = [];
    for (int i = 0; i < files.length; i++) {
      final url = await uploadEvidenceImage(
        file: files[i],
        reportId: reportId,
        customFileName: 'evidence_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      downloadUrls.add(url);
    }
    return downloadUrls;
  }
}
