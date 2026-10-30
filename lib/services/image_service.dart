import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Servicio de almacenamiento y subida de imágenes utilizando la API pública de ImgBB
class ImageService {
  ImageService({
    http.Client? client,
    ImagePicker? picker,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _picker = picker ?? ImagePicker(),
        _apiKey = apiKey ?? defaultApiKey;

  final http.Client _client;
  final ImagePicker _picker;
  final String _apiKey;

  /// API Key oficial asignada para LabFix
  static const String defaultApiKey = '45abdbd819a9d555391431aae885365f';

  /// Endpoint oficial de subida de ImgBB
  static const String uploadEndpoint = 'https://api.imgbb.com/1/upload';

  /// Permite capturar una imagen desde la cámara del dispositivo
  Future<XFile?> pickImageFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
    } catch (e) {
      debugPrint('Error al capturar foto desde cámara: $e');
      return null;
    }
  }

  /// Permite seleccionar una imagen desde la galería
  Future<XFile?> pickImageFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
    } catch (e) {
      debugPrint('Error al seleccionar imagen desde galería: $e');
      return null;
    }
  }

  /// Permite seleccionar múltiples imágenes de evidencia desde la galería
  Future<List<XFile>> pickMultiImages() async {
    try {
      return await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
    } catch (e) {
      debugPrint('Error al seleccionar múltiples imágenes: $e');
      return [];
    }
  }

  /// Sube un archivo de imagen (XFile) a la API de ImgBB y retorna el enlace público (data.url)
  Future<String> uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final fileName = file.name.isNotEmpty
        ? file.name
        : 'evidence_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return uploadImageBytes(bytes, fileName: fileName);
  }

  /// Convierte los bytes a formato multipart/form-data y ejecuta la petición POST a ImgBB
  Future<String> uploadImageBytes(
    Uint8List bytes, {
    String fileName = 'evidence.jpg',
  }) async {
    try {
      final uri = Uri.parse('$uploadEndpoint?key=$_apiKey');
      final request = http.MultipartRequest('POST', uri);

      request.fields['key'] = _apiKey;
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap =
            jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>?;

        if (data != null && data['url'] != null) {
          final publicUrl = data['url'].toString();
          debugPrint('✅ Imagen subida a ImgBB exitosamente: $publicUrl');
          return publicUrl;
        }

        throw Exception('La respuesta de ImgBB no contiene data.url');
      } else {
        throw Exception(
          'ImgBB API error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error subiendo imagen a ImgBB: $e');
      rethrow;
    }
  }

  /// Sube una lista de imágenes de evidencia y retorna las URLs públicas obtenidas
  Future<List<String>> uploadMultipleImages(List<XFile> files) async {
    final List<String> urls = [];
    for (final file in files) {
      try {
        final url = await uploadImage(file);
        if (url.trim().isNotEmpty) {
          urls.add(url.trim());
        }
      } catch (e) {
        debugPrint('Fallo al subir evidencia individual (${file.name}): $e');
      }
    }
    return urls;
  }
}
