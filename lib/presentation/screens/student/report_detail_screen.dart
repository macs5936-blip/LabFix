import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/app_theme.dart';
import '../../../data/report_model.dart';
import '../../../models/report_model.dart';
import '../../../services/firestore_service.dart';
import '../../widgets/urgency_badge.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({
    super.key,
    required this.report,
    this.isTechnician = false,
    this.auth,
    this.firestore,
    this.firestoreService,
  });

  final IncidentReport report;
  final bool isTechnician;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final FirestoreService? firestoreService;

  factory ReportDetailScreen.fromReportModel({
    Key? key,
    required ReportModel reportModel,
    bool isTechnician = false,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirestoreService? firestoreService,
  }) {
    return ReportDetailScreen(
      key: key,
      report: IncidentReport.fromReportModel(reportModel),
      isTechnician: isTechnician,
      auth: auth,
      firestore: firestore,
      firestoreService: firestoreService,
    );
  }

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Guarda el mensaje en la subcolección 'reports/{reportId}/messages'
  /// con los campos: senderId, messageText, y createdAt
  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty) return;

    FirebaseAuth? currentAuth = widget.auth;
    FirebaseFirestore? currentFirestore = widget.firestore;
    try {
      if (currentAuth == null && Firebase.apps.isNotEmpty) {
        currentAuth = FirebaseAuth.instance;
      }
      if (currentFirestore == null && Firebase.apps.isNotEmpty) {
        currentFirestore = FirebaseFirestore.instance;
      }
    } catch (_) {}

    final user = currentAuth?.currentUser;
    final senderId = user?.uid ??
        (widget.isTechnician
            ? 'tech_espoch_01'
            : (widget.report.userId ?? 'student_espoch_01'));
    final authorName = (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : (widget.isTechnician ? 'Técnico de Laboratorio' : 'Estudiante FIE');

    // 1. Reflejo local inmediato (para feedback instantáneo y pruebas)
    final localMsg = TicketMessage(
      author: authorName,
      body: body,
      sentAt: DateTime.now(),
      isTechnician: widget.isTechnician,
      senderId: senderId,
    );

    setState(() {
      widget.report.messages.add(localMsg);
      _messageController.clear();
    });

    // 2. Persistencia en la subcolección de Cloud Firestore
    final cleanDocId = widget.report.rawDocId ??
        (widget.report.id.startsWith('#')
            ? widget.report.id.substring(1)
            : widget.report.id);

    if (currentFirestore != null && cleanDocId.isNotEmpty) {
      try {
        final service = widget.firestoreService ??
            FirestoreService(firestore: currentFirestore);
        await service.sendReportMessage(
          reportId: cleanDocId,
          senderId: senderId,
          messageText: body,
          author: authorName,
          isTechnician: widget.isTechnician,
        );
      } catch (e) {
        debugPrint('Aviso al guardar mensaje en subcolección: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    FirebaseAuth? currentAuth = widget.auth;
    FirebaseFirestore? currentFirestore = widget.firestore;
    try {
      if (currentAuth == null && Firebase.apps.isNotEmpty) {
        currentAuth = FirebaseAuth.instance;
      }
      if (currentFirestore == null && Firebase.apps.isNotEmpty) {
        currentFirestore = FirebaseFirestore.instance;
      }
    } catch (_) {}

    final cleanDocId = report.rawDocId ??
        (report.id.startsWith('#') ? report.id.substring(1) : report.id);

    final service = widget.firestoreService ??
        (currentFirestore != null
            ? FirestoreService(firestore: currentFirestore)
            : (Firebase.apps.isNotEmpty ? FirestoreService() : null));

    Stream<List<Map<String, dynamic>>>? messagesStream;
    if (service != null && currentFirestore != null && cleanDocId.isNotEmpty) {
      try {
        messagesStream = service.getReportMessages(cleanDocId);
      } catch (_) {
        messagesStream = null;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Reporte')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    sliver: SliverList.list(
                      children: [
                        _IncidentSummary(report: report),
                        const SizedBox(height: 20),
                        Text(
                          'Seguimiento',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 9),
                        _ReportTimeline(report: report),
                        const SizedBox(height: 20),
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: messagesStream,
                          builder: (context, snapshot) {
                            final List<TicketMessage> messages = [];

                            if (snapshot.hasData &&
                                snapshot.data != null &&
                                snapshot.data!.isNotEmpty) {
                              for (final doc in snapshot.data!) {
                                final text = (doc['messageText'] as String?) ??
                                    (doc['body'] as String?) ??
                                    '';
                                final senderId = (doc['senderId'] as String?) ??
                                    (doc['authorId'] as String?);
                                final author = (doc['author'] as String?) ??
                                    (doc['authorName'] as String?) ??
                                    'Usuario';
                                final isTech =
                                    (doc['isTechnician'] as bool?) ?? false;

                                DateTime sentAt = DateTime.now();
                                final ts = doc['createdAt'] ?? doc['sentAt'];
                                if (ts is Timestamp) {
                                  sentAt = ts.toDate();
                                } else if (ts is DateTime) {
                                  sentAt = ts;
                                }

                                messages.add(
                                  TicketMessage(
                                    author: author,
                                    body: text,
                                    sentAt: sentAt,
                                    isTechnician: isTech,
                                    senderId: senderId,
                                  ),
                                );
                              }
                            }

                            // Si la subcolección en Firestore no tiene registros aún o estamos offline/test
                            if (messages.isEmpty) {
                              messages.addAll(report.messages);
                            } else {
                              // Asegura que mensajes enviados recientemente en memoria no se pierdan
                              for (final local in report.messages) {
                                final exists = messages.any((m) =>
                                    m.body == local.body &&
                                    m.sentAt
                                            .difference(local.sentAt)
                                            .inSeconds
                                            .abs() <
                                        5);
                                if (!exists) {
                                  messages.add(local);
                                }
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Conversación del ticket',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                    ),
                                    Text(
                                      '${messages.length} mensajes',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (messages.isEmpty)
                                  const _EmptyConversation()
                                else
                                  for (final message in messages) ...[
                                    _MessageBubble(message: message),
                                    const SizedBox(height: 8),
                                  ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _MessageComposer(
              controller: _messageController,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentSummary extends StatelessWidget {
  const _IncidentSummary({required this.report});

  final IncidentReport report;

  void _openImageDialog(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) =>
                      progress == null
                          ? child
                          : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text(
                      'No se pudo cargar la imagen',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar URLs válidas (no vacías y con esquema http/https)
    final validImageUrls = report.imageUrls
        .where((url) =>
            url.trim().isNotEmpty &&
            (url.startsWith('http://') || url.startsWith('https://')))
        .map((url) => url.trim())
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.id,
                    style: const TextStyle(
                      color: AppColors.fieBlue,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                UrgencyBadge(urgency: report.urgency),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Creado el ${_formatDateTime(report.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 22),
            _SummaryField(
              icon: Icons.science_outlined,
              label: 'Laboratorio',
              value: '${report.building} · ${report.laboratory}',
            ),
            const SizedBox(height: 11),
            _SummaryField(
              icon: Icons.memory_outlined,
              label: 'Equipo',
              value: report.machine,
            ),
            if (report.category != null) ...[
              const SizedBox(height: 11),
              _SummaryField(
                icon: Icons.category_outlined,
                label: 'Categoría',
                value: report.category!,
              ),
            ],
            if (report.latitude != null && report.longitude != null) ...[
              const SizedBox(height: 11),
              _SummaryField(
                icon: Icons.location_on_outlined,
                label: 'Ubicación GPS (Campus)',
                value:
                    'Lat: ${report.latitude!.toStringAsFixed(4)}, Lng: ${report.longitude!.toStringAsFixed(4)}',
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Descripción del estudiante',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              report.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Evidencia fotográfica',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),

            // Renderizado seguro de evidencias fotográficas
            if (validImageUrls.isNotEmpty) ...[
              SizedBox(
                height: 125,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: validImageUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final url = validImageUrls[index];
                    return InkWell(
                      onTap: () => _openImageDialog(context, url),
                      borderRadius: BorderRadius.circular(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 150,
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: AppColors.canvas,
                                  padding: const EdgeInsets.all(8),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        color: AppColors.muted,
                                        size: 26,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Error al cargar imagen',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.muted,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  final total =
                                      loadingProgress.expectedTotalBytes;
                                  final loaded =
                                      loadingProgress.cumulativeBytesLoaded;
                                  return Center(
                                    child: SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.fieBlue,
                                        value: total != null
                                            ? loaded / total
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                right: 6,
                                bottom: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else if (report.hasEvidence) ...[
              // Vista previa simulada cuando se indica evidencia pero no hay URLs remotas
              Container(
                width: double.infinity,
                height: 116,
                decoration: BoxDecoration(
                  color: AppColors.fieBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      color: AppColors.fieBlue,
                      size: 30,
                    ),
                    SizedBox(height: 5),
                    Text(
                      'evidencia_seleccionada.jpg · Vista previa simulada',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Sin evidencia fotográfica adjunta
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.muted,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Sin evidencia adjunta',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (report.resolutionNotes != null &&
                report.resolutionNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 18,
                          color: AppColors.green,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Notas de Resolución del Técnico',
                          style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.resolutionNotes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryField extends StatelessWidget {
  const _SummaryField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.fieBlue),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportTimeline extends StatelessWidget {
  const _ReportTimeline({required this.report});

  final IncidentReport report;

  @override
  Widget build(BuildContext context) {
    final resolved = report.status == ReportStatus.resuelto;
    final assigned = report.status != ReportStatus.pendiente;
    final diagnosing = report.status == ReportStatus.enAtencion;
    final steps = [
      _TimelineStepData(
        title: 'Reporte Registrado',
        subtitle: 'Completado',
        time: report.createdAt,
        isEstimated: false,
        complete: true,
      ),
      _TimelineStepData(
        title: 'Asignado a Soporte Técnico',
        subtitle: assigned ? 'En atención' : 'Pendiente de asignación',
        time: assigned
            ? report.createdAt.add(const Duration(minutes: 20))
            : report.createdAt.add(const Duration(hours: 1)),
        isEstimated: !assigned,
        complete: assigned,
        current: report.status == ReportStatus.pendiente,
      ),
      _TimelineStepData(
        title: 'En Diagnóstico / Mantenimiento',
        subtitle: diagnosing
            ? 'En proceso'
            : resolved
                ? 'Completado'
                : 'Pendiente',
        time: resolved || diagnosing
            ? report.createdAt.add(const Duration(hours: 1))
            : report.createdAt.add(const Duration(hours: 3)),
        isEstimated: !resolved && !diagnosing,
        complete: resolved,
        current: diagnosing,
      ),
      _TimelineStepData(
        title: 'Incidencia Resuelta',
        subtitle: resolved ? 'Completado' : 'Pendiente',
        time: resolved
            ? report.createdAt.add(const Duration(hours: 2))
            : report.createdAt.add(const Duration(hours: 4)),
        isEstimated: !resolved,
        complete: resolved,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Column(
          children: [
            for (var index = 0; index < steps.length; index++)
              _TimelineRow(
                step: steps[index],
                isLast: index == steps.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStepData {
  const _TimelineStepData({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isEstimated,
    this.complete = false,
    this.current = false,
  });

  final String title;
  final String subtitle;
  final DateTime time;
  final bool isEstimated;
  final bool complete;
  final bool current;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.isLast});

  final _TimelineStepData step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = step.complete || step.current
        ? AppColors.fieBlue
        : AppColors.muted;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(
                  step.complete
                      ? Icons.check_circle
                      : step.current
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                  color: color,
                  size: 20,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: step.complete
                          ? AppColors.fieBlue.withValues(alpha: 0.35)
                          : AppColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      color: step.complete || step.current
                          ? Theme.of(context).colorScheme.onSurface
                          : AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${step.subtitle} · ${step.isEstimated ? 'Estimado' : 'Fecha'}: ${_formatDateTime(step.time)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Aún no hay mensajes. Escribe aquí si necesitas ampliar información del reporte.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final ownMessage = !message.isTechnician;
    return Align(
      alignment: ownMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ownMessage
              ? AppColors.fieBlue
              : Theme.of(context).colorScheme.surface,
          border: ownMessage ? null : Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.author,
              style: TextStyle(
                color: ownMessage ? AppColors.gold : AppColors.fieBlue,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.body,
              style: TextStyle(
                color: ownMessage
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _formatDateTime(message.sentAt),
              style: TextStyle(
                color: ownMessage ? Colors.white70 : AppColors.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('ticket-message-input'),
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('send-ticket-message'),
              tooltip: 'Enviar comentario',
              onPressed: onSend,
              icon: const Icon(Icons.send_outlined),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.fieBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${formatReportDate(date)} · ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
}
