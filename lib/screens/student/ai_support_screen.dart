import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme/app_theme.dart';
import '../../services/gemini_ai_service.dart';

/// Modelo de mensaje de chat para el Asistente IA
class AiChatMessage {
  AiChatMessage({
    required this.text,
    required this.isAssistant,
    this.imageBytes,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String text;
  final bool isAssistant;
  final Uint8List? imageBytes;
  final DateTime timestamp;
}

/// Pantalla de Asistente IA de Soporte Técnico para estudiantes de la ESPOCH.
///
/// Conectada en vivo a la API de Gemini con soporte multimodal (texto e imágenes).
class AiSupportScreen extends StatefulWidget {
  const AiSupportScreen({
    super.key,
    this.geminiService,
  });

  final GeminiAiService? geminiService;

  @override
  State<AiSupportScreen> createState() => _AiSupportScreenState();
}

class _AiSupportScreenState extends State<AiSupportScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final GeminiAiService _aiService =
      widget.geminiService ?? GeminiAiService();

  final List<AiChatMessage> _messages = [];
  bool _isLoading = false;
  XFile? _attachedImage;
  Uint8List? _attachedImageBytes;

  @override
  void initState() {
    super.initState();
    _messages.add(
      AiChatMessage(
        text:
            '¡Hola! Soy el asistente técnico oficial de los laboratorios ESPOCH '
            '(FIE y Ciencias Básicas). ¿Qué problema presentas en tus equipos, '
            'red o software? Puedes describirlo o adjuntar una foto de evidencia.',
        isAssistant: true,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Muestra diálogo o bottom sheet para seleccionar foto desde cámara o galería
  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Adjuntar evidencia visual',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.fieBlue,
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
                title: const Text('Tomar foto con la cámara'),
                subtitle: const Text('Fotografía directa del monitor o equipo'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.fieBlue.withValues(alpha: 0.15),
                  child: const Icon(Icons.photo_library,
                      color: AppColors.fieBlue, size: 20),
                ),
                title: const Text('Seleccionar de la galería'),
                subtitle: const Text('Cargar captura de pantalla o imagen'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = source == ImageSource.camera
          ? await _aiService.pickImageFromCamera()
          : await _aiService.pickImageFromGallery();

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _attachedImage = file;
          _attachedImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error al seleccionar evidencia para el chat: $e');
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachedImage = null;
      _attachedImageBytes = null;
    });
  }

  /// Envía el mensaje y evidencia a la API de Gemini
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    final imageBytes = _attachedImageBytes;
    final imageFile = _attachedImage;

    if (text.isEmpty && imageBytes == null) return;
    if (_isLoading) return;

    // Agregar mensaje del usuario a la lista visual inmediatamente
    setState(() {
      _messages.add(
        AiChatMessage(
          text: text.isNotEmpty ? text : 'Evidencia gráfica adjuntada',
          isAssistant: false,
          imageBytes: imageBytes,
        ),
      );
      _textController.clear();
      _attachedImage = null;
      _attachedImageBytes = null;
      _isLoading = true;
    });

    _scrollToBottom();

    // Consulta en vivo a la API de Gemini
    try {
      final response = await _aiService.sendMessage(
        prompt: text,
        imageBytes: imageBytes,
        imageFile: imageFile,
      );

      if (mounted) {
        setState(() {
          _messages.add(
            AiChatMessage(
              text: response,
              isAssistant: true,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error al consultar Gemini API: $e');
      if (mounted) {
        setState(() {
          _messages.add(
            AiChatMessage(
              text: '⚠️ Error al comunicarse con Gemini API:\n$e',
              isAssistant: true,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _resetChat() {
    _aiService.resetSession();
    setState(() {
      _messages.clear();
      _messages.add(
        AiChatMessage(
          text:
              '¡Hola! Soy el asistente técnico oficial de los laboratorios ESPOCH '
              '(FIE y Ciencias Básicas). ¿En qué problema técnico puedo ayudarte hoy?',
          isAssistant: true,
        ),
      );
      _attachedImage = null;
      _attachedImageBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Encabezado del Asistente ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.fieBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.fieBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Soporte rápido',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Asistente IA (Gemini) · Conectado en vivo',
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Nueva conversación',
                  icon: const Icon(Icons.refresh, color: AppColors.muted),
                  onPressed: _resetChat,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.line),

          // ── Historial de chat dinámico en tiempo real ───────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _AiChatBubble(message: _messages[index]);
              },
            ),
          ),

          // ── Indicador de carga dinámico mientras Gemini responde ───────────
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.fieBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.fieBlue.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: const [
                  SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.fieBlue),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Analizando tu consulta y evidencia...',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.fieBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Previsualización de imagen adjunta antes de enviar ─────────────
          if (_attachedImageBytes != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.fieBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      _attachedImageBytes!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evidencia fotográfica lista',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Se enviará junto a tu consulta a Gemini',
                          style: TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Quitar imagen',
                    onPressed: _removeAttachment,
                  ),
                ],
              ),
            ),

          // ── Barra inferior de entrada de texto y adjunto multimodal ────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              14,
              6,
              14,
              12 + MediaQuery.paddingOf(context).bottom * 0.5,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: _attachedImageBytes != null
                          ? 'Escribe un detalle de la falla (opcional)...'
                          : 'Describe la falla en el laboratorio...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: IconButton(
                        key: const Key('ai-attach-button'),
                        tooltip: 'Adjuntar foto de evidencia',
                        icon: Icon(
                          _attachedImageBytes != null
                              ? Icons.image
                              : Icons.add_photo_alternate_outlined,
                          color: _attachedImageBytes != null
                              ? AppColors.fieBlue
                              : AppColors.muted,
                        ),
                        onPressed: _showAttachmentOptions,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: const Key('ai-send-button'),
                  tooltip: 'Enviar a Gemini',
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: const Icon(Icons.arrow_upward),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.fieBlue,
                    disabledBackgroundColor:
                        AppColors.fieBlue.withValues(alpha: 0.35),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Burbuja de mensaje individual para el chat
class _AiChatBubble extends StatelessWidget {
  const _AiChatBubble({required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.isAssistant;
    return Align(
      alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAssistant
              ? Theme.of(context).colorScheme.surface
              : AppColors.fieBlue,
          border: isAssistant ? Border.all(color: AppColors.line) : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAssistant ? 4 : 16),
            bottomRight: Radius.circular(isAssistant ? 16 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isAssistant ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            // Si el usuario envió una imagen, se renderiza la miniatura dentro de la burbuja
            if (message.imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  message.imageBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                ),
              ),
              const SizedBox(height: 8),
            ],
            SelectableText(
              message.text,
              style: TextStyle(
                color: isAssistant
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.white,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef AiAssistantScreen = AiSupportScreen;

