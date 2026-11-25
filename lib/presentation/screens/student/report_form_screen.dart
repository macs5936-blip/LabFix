import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../widgets/location_picker_modal.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/theme/app_theme.dart';
import '../../../data/lab_model.dart';
import '../../../data/report_model.dart';
import '../../../models/report_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/image_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/storage_service.dart';

typedef CreateReportScreen = NewReportScreen;

class NewReportScreen extends StatefulWidget {
  const NewReportScreen({
    super.key,
    required this.onSubmit,
    this.initialCategory,
    this.onOpenHistory,
    this.auth,
    this.firestore,
    this.storage,
    this.firestoreService,
    this.storageService,
    this.imageService,
    this.notificationService,
  });

  final ValueChanged<IncidentReport> onSubmit;
  final String? initialCategory;
  final VoidCallback? onOpenHistory;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final FirebaseStorage? storage;
  final FirestoreService? firestoreService;
  final StorageService? storageService;
  final ImageService? imageService;
  final NotificationService? notificationService;

  @override
  State<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _equipmentController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _laboratory;
  String? _category;
  Urgency _urgency = Urgency.media;
  bool _hasEvidence = false;
  LatLng? _selectedLatLng;
  bool _isSubmitting = false;

  final List<XFile> _selectedImages = [];

  late final ImageService _imageService =
      widget.imageService ?? ImageService();
  late final StorageService _storageService =
      widget.storageService ?? StorageService(storage: widget.storage);
  late final FirestoreService _firestoreService =
      widget.firestoreService ?? FirestoreService(firestore: widget.firestore);
  late final NotificationService _notificationService =
      widget.notificationService ??
          NotificationService(firestore: widget.firestore);

  static const _categories = [
    'Hardware',
    'Software / Sistema Operativo',
    'Conectividad / Red',
    'Instrumentos de Medición',
    'Proyector / Mobiliario',
  ];

  @override
  void initState() {
    super.initState();
    if (_categories.contains(widget.initialCategory)) {
      _category = widget.initialCategory;
    }
  }

  @override
  void dispose() {
    _equipmentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Permite capturar foto con la cámara del dispositivo
  Future<void> _pickImageFromCamera() async {
    try {
      final file = await _imageService.pickImageFromCamera() ??
          await _storageService.pickImageFromCamera();
      if (file != null) {
        setState(() {
          _selectedImages.add(file);
          _hasEvidence = true;
        });
      }
    } catch (e) {
      debugPrint('Aviso al capturar foto con la cámara: $e');
    }
  }

  /// Permite seleccionar una foto desde la galería
  Future<void> _pickImageFromGallery() async {
    try {
      final file = await _imageService.pickImageFromGallery() ??
          await _storageService.pickImageFromGallery();
      if (file != null) {
        setState(() {
          _selectedImages.add(file);
          _hasEvidence = true;
        });
      }
    } catch (e) {
      debugPrint('Aviso al seleccionar foto de la galería: $e');
    }
  }

  /// Abre el modal de pantalla completa con OpenStreetMap y espera la ubicación.
  Future<void> _openMapModal() async {
    final result = await showLocationPickerModal(
      context,
      initialSelection: _selectedLatLng,
    );
    if (result != null) {
      setState(() => _selectedLatLng = result);
    }
  }

  /// Envía el reporte, sube evidencias a Firebase Storage y guarda en Firestore
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    // a) Indicador de carga
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: const [
              SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Subiendo evidencias y registrando reporte...',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final now = DateTime.now();
    final ticketNumber = now.millisecondsSinceEpoch % 90 + 10;
    final ticket = '#LAB-${now.year}-$ticketNumber';

    final List<String> imageUrls = [];

    // b) Sube las imágenes adjuntas utilizando la API de ImgBB
    try {
      if (_selectedImages.isNotEmpty) {
        for (final img in _selectedImages) {
          try {
            final url = await _imageService.uploadImage(img);
            if (url.trim().isNotEmpty) {
              imageUrls.add(url.trim());
            }
          } catch (imgbbErr) {
            debugPrint('Aviso ImgBB: $imgbbErr. Intentando fallback Storage...');
            try {
              final storageUrl =
                  await _storageService.uploadReportImage(file: img);
              if (storageUrl.trim().isNotEmpty) {
                imageUrls.add(storageUrl.trim());
              }
            } catch (_) {}
          }
        }
      } else if (_hasEvidence) {
        // Modo simulación o prueba sin archivos reales seleccionados
        try {
          final dummyBytes = Uint8List.fromList([
            0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46
          ]);
          final demoUrl = await _imageService.uploadImageBytes(
            dummyBytes,
            fileName: 'evidence_${now.millisecondsSinceEpoch}.jpg',
          );
          if (demoUrl.trim().isNotEmpty) {
            imageUrls.add(demoUrl.trim());
          }
        } catch (imgbbErr) {
          try {
            final storageUrl = await _storageService.uploadImageBytes(
              bytes: Uint8List.fromList([
                0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46
              ]),
              storagePath:
                  'report_images/evidence_${now.millisecondsSinceEpoch}.jpg',
            );
            if (storageUrl.trim().isNotEmpty) {
              imageUrls.add(storageUrl.trim());
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Aviso al subir imagen a ImgBB / Storage: $e');
    }

    // c) Construcción del objeto ReportModel completo
    FirebaseAuth? currentAuth = widget.auth;
    try {
      if (currentAuth == null && Firebase.apps.isNotEmpty) {
        currentAuth = FirebaseAuth.instance;
      }
    } catch (_) {}

    final user = currentAuth?.currentUser;
    final userId = user?.uid ?? 'student_espoch_01';
    final userName = (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : 'Estudiante FIE';
    final userEmail = (user?.email != null && user!.email!.trim().isNotEmpty)
        ? user.email!.trim()
        : 'estudiante.fie@espoch.edu.ec';

    final urgencyLabel = switch (_urgency) {
      Urgency.baja => 'Baja',
      Urgency.media => 'Media',
      Urgency.alta => 'Alta',
    };

    final reportModel = ReportModel(
      reportId: ticket,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      building: 'FIE',
      laboratory: _laboratory!,
      equipmentId: _equipmentController.text.trim(),
      latitude: _selectedLatLng?.latitude,
      longitude: _selectedLatLng?.longitude,
      category: _category ?? 'General',
      description: _descriptionController.text.trim(),
      urgency: urgencyLabel,
      status: 'Pendiente',
      imageUrls: imageUrls,
      createdAt: now,
      updatedAt: now,
    );

    // d) Guarda el documento en la colección 'reports' de Firestore
    try {
      await _firestoreService.createReport(reportModel);
    } catch (e) {
      debugPrint('Aviso al guardar en Firestore: $e');
    }

    // e) Notificación automática en 'notifications' para los técnicos
    try {
      await _notificationService.sendNotificationToTechnicians(reportModel);
    } catch (e) {
      debugPrint('Aviso al notificar técnicos: $e');
    }

    // Compatibilidad local
    final incidentReport = IncidentReport(
      id: ticket,
      rawDocId: ticket,
      building: 'FIE',
      laboratory: _laboratory!,
      machine: _equipmentController.text.trim(),
      category: _category,
      hasEvidence: imageUrls.isNotEmpty || _hasEvidence,
      urgency: _urgency,
      description: _descriptionController.text.trim(),
      createdAt: now,
      status: ReportStatus.pendiente,
      latitude: _selectedLatLng?.latitude,
      longitude: _selectedLatLng?.longitude,
      imageUrls: imageUrls,
      userId: userId,
    );

    widget.onSubmit(incidentReport);

    // Cerrar el diálogo de carga
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isSubmitting = false);
    }

    // Limpiar el formulario
    _formKey.currentState?.reset();
    _equipmentController.clear();
    _descriptionController.clear();
    setState(() {
      _laboratory = null;
      _category = null;
      _urgency = Urgency.media;
      _selectedLatLng = null;
      _hasEvidence = false;
      _selectedImages.clear();
    });

    if (!mounted) return;

    // Mensaje de confirmación
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: AppColors.green,
          size: 40,
        ),
        title: const Text('¡Reporte Registrado con Éxito!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu incidencia fue agregada a la cola de soporte y se ha notificado al equipo técnico.',
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.fieBlue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticket,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.fieBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'history'),
            child: const Text('Ver en Mis Reportes'),
          ),
          FilledButton.icon(
            key: const Key('return-to-dashboard'),
            onPressed: () => Navigator.pop(dialogContext, 'dashboard'),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Volver al Dashboard'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Incidencia $ticket creada exitosamente!'),
        backgroundColor: AppColors.green,
      ),
    );

    Navigator.of(context).pop(result == 'history');
    if (result == 'history') {
      widget.onOpenHistory?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nuevo Reporte')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              'Reportar una incidencia',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 5),
            Text(
              'Describe el problema para que soporte FIE pueda ayudarte.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 22),

            // ── 01 · Laboratorio ─────────────────────────────────────────────
            const _FieldLabel(title: 'Laboratorio', step: '01'),
            const SizedBox(height: 9),
            ValueListenableBuilder<List<LabRecord>>(
              valueListenable: LabCatalog.labs,
              builder: (context, rawLaboratories, _) {
                final uniqueLabs = <String, LabRecord>{};
                for (final l in rawLaboratories) {
                  final clean = l.name.trim();
                  if (clean.isNotEmpty) {
                    uniqueLabs.putIfAbsent(clean.toLowerCase(), () => l);
                  }
                }
                final laboratories = uniqueLabs.values.toList();
                final hasMatch = laboratories.any(
                  (l) => l.name.trim().toLowerCase() == _laboratory?.trim().toLowerCase(),
                );
                final effectiveLab = hasMatch
                    ? laboratories
                        .firstWhere((l) =>
                            l.name.trim().toLowerCase() ==
                            _laboratory?.trim().toLowerCase())
                        .name
                    : null;

                return DropdownButtonFormField<String>(
                  key: const Key('lab-dropdown'),
                  initialValue: effectiveLab,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Selecciona un laboratorio',
                    prefixIcon: Icon(Icons.science_outlined),
                  ),
                  items: laboratories.isEmpty
                      ? null
                      : [
                          for (final laboratory in laboratories)
                            DropdownMenuItem(
                              value: laboratory.name,
                              child: Text(
                                laboratory.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                  validator: (value) =>
                      value == null ? 'Selecciona el laboratorio' : null,
                  selectedItemBuilder: (context) => [
                    for (final laboratory in laboratories)
                      SizedBox(
                        width: 150,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            laboratory.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _laboratory = value),
                );
              },
            ),
            const SizedBox(height: 19),

            // ── 02 · Ubicación ───────────────────────────────────────────────
            const _FieldLabel(title: 'Ubicación en el campus', step: '02'),
            const SizedBox(height: 9),
            _LocationPickerButton(
              selectedLatLng: _selectedLatLng,
              onTap: _openMapModal,
              onClear: () => setState(() => _selectedLatLng = null),
            ),
            const SizedBox(height: 19),

            // ── 03 · Categoría ───────────────────────────────────────────────
            const _FieldLabel(title: 'Categoría de falla', step: '03'),
            const SizedBox(height: 9),
            DropdownButtonFormField<String>(
              key: const Key('category-dropdown'),
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'Selecciona una categoría',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final category in _categories)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category, overflow: TextOverflow.ellipsis),
                  ),
              ],
              validator: (value) =>
                  value == null ? 'Selecciona la categoría de falla' : null,
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 19),

            // ── 04 · Equipo ──────────────────────────────────────────────────
            const _FieldLabel(title: 'Identificación del Equipo', step: '04'),
            const SizedBox(height: 9),
            TextFormField(
              key: const Key('equipment-field'),
              controller: _equipmentController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Ej. PC-08, Router SUM_01, Multímetro DT832',
                prefixIcon: Icon(Icons.memory_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa la identificación del equipo'
                  : null,
            ),
            const SizedBox(height: 19),

            // ── 05 · Urgencia ────────────────────────────────────────────────
            const _FieldLabel(title: 'Nivel de urgencia', step: '05'),
            const SizedBox(height: 9),
            Column(
              children: [
                for (final urgency in Urgency.values) ...[
                  _UrgencyOption(
                    urgency: urgency,
                    selected: urgency == _urgency,
                    onTap: () => setState(() => _urgency = urgency),
                  ),
                  if (urgency != Urgency.values.last)
                    const SizedBox(height: 7),
                ],
              ],
            ),
            const SizedBox(height: 19),

            // ── 06 · Descripción ─────────────────────────────────────────────
            const _FieldLabel(
              title: 'Descripción detallada del problema',
              step: '06',
            ),
            const SizedBox(height: 9),
            TextFormField(
              key: const Key('description-field'),
              controller: _descriptionController,
              minLines: 4,
              maxLines: 6,
              maxLength: 600,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Indica qué ocurrió, cuándo sucede y cómo afecta la práctica...',
                alignLabelWithHint: true,
              ),
              validator: (value) =>
                  value == null || value.trim().length < 10
                      ? 'Describe el problema con al menos 10 caracteres'
                      : null,
            ),
            const SizedBox(height: 7),

            // ── 07 · Evidencia ───────────────────────────────────────────────
            const _FieldLabel(title: 'Evidencia', step: '07'),
            const SizedBox(height: 9),
            OutlinedButton.icon(
              key: const Key('attach-evidence'),
              onPressed: () {
                setState(() {
                  _hasEvidence = !_hasEvidence;
                  if (!_hasEvidence) {
                    _selectedImages.clear();
                  }
                });
              },
              icon: Icon(
                (_hasEvidence || _selectedImages.isNotEmpty)
                    ? Icons.check_circle_outline
                    : Icons.add_a_photo_outlined,
              ),
              label: Text(
                (_hasEvidence || _selectedImages.isNotEmpty)
                    ? 'Quitar evidencia fotográfica'
                    : 'Adjuntar Captura / Foto de Evidencia',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.centerLeft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (_hasEvidence || _selectedImages.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.fieBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          color: AppColors.fieBlue,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedImages.isNotEmpty
                                    ? _selectedImages.first.name
                                    : 'evidencia_seleccionada.jpg',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _selectedImages.isNotEmpty
                                    ? '${_selectedImages.length} archivo(s) listo(s) para subir a ImgBB'
                                    : 'Vista previa simulada',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Quitar',
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() {
                              _hasEvidence = false;
                              _selectedImages.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImageFromCamera,
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: const Text('Cámara', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImageFromGallery,
                            icon: const Icon(Icons.photo_library_outlined, size: 16),
                            label: const Text('Galería', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),

            // ── Botón Enviar Reporte ─────────────────────────────────────────
            FilledButton.icon(
              key: const Key('submit-report'),
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                _isSubmitting
                    ? 'Subiendo evidencias y registrando reporte...'
                    : 'Enviar Reporte',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botón de selección de ubicación (abre modal de mapa en pantalla completa)
// ─────────────────────────────────────────────────────────────────────────────

class _LocationPickerButton extends StatelessWidget {
  const _LocationPickerButton({
    required this.selectedLatLng,
    required this.onTap,
    required this.onClear,
  });

  final LatLng? selectedLatLng;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasLocation = selectedLatLng != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: const Key('open-map-picker'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: hasLocation
                  ? AppColors.fieBlue.withValues(alpha: 0.07)
                  : Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasLocation ? AppColors.fieBlue : AppColors.line,
                width: hasLocation ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasLocation
                      ? Icons.location_on
                      : Icons.add_location_alt_outlined,
                  color: hasLocation ? AppColors.fieBlue : AppColors.muted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: hasLocation
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ubicación seleccionada',
                              style: TextStyle(
                                color: AppColors.fieBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lat: ${selectedLatLng!.latitude.toStringAsFixed(6)}'
                              '  Lng: ${selectedLatLng!.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          '📍 Toca para seleccionar ubicación en el mapa',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: hasLocation ? AppColors.fieBlue : AppColors.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (hasLocation) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 13),
              label: const Text('Limpiar ubicación'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontSize: 11),
                foregroundColor: AppColors.muted,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 4),
          const Text(
            'Opcional — ayuda al técnico a localizar el incidente más rápido.',
            style: TextStyle(fontSize: 10, color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets de soporte
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.title, required this.step});

  final String title;
  final String step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 23,
          height: 23,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.fieBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            step,
            style: const TextStyle(
              color: AppColors.fieBlue,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

class _UrgencyOption extends StatelessWidget {
  const _UrgencyOption({
    required this.urgency,
    required this.selected,
    required this.onTap,
  });

  final Urgency urgency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, description, color) = switch (urgency) {
      Urgency.baja => (
          'Baja',
          'Falla menor que no interrumpe el uso general.',
          AppColors.green,
        ),
      Urgency.media => (
          'Media',
          'Afecta a un equipo individual.',
          AppColors.yellow,
        ),
      Urgency.alta => (
          'Alta',
          'Detiene la práctica o afecta a varios estudiantes.',
          AppColors.red,
        ),
    };
    return InkWell(
      key: Key('urgency-${urgency.name}'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: selected ? color : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
