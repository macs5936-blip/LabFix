import 'package:flutter/material.dart';

import '../../../config/theme/app_theme.dart';

class DiagnosticChatbotScreen extends StatefulWidget {
  const DiagnosticChatbotScreen({super.key, required this.onCreateReport});

  final ValueChanged<String> onCreateReport;

  @override
  State<DiagnosticChatbotScreen> createState() =>
      _DiagnosticChatbotScreenState();
}

class _DiagnosticChatbotScreenState extends State<DiagnosticChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_DiagnosticMessage> _messages = [
    const _DiagnosticMessage(
      text: 'Hola. Puedo guiarte con pasos rápidos para problemas comunes del laboratorio. ¿Qué está ocurriendo?',
      isBot: true,
    ),
  ];

  String? _selectedCategory;
  bool _showEscalation = false;

  static const _quickOptions = [
    'PC no enciende / Pantalla negra',
    'Sin conexión a red / Ethernet',
    'Fallos en el proyector',
    'Software congelado / Sin licencias',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _categoryFor(String question) {
    final normalized = question.toLowerCase();
    if (normalized.contains('red') ||
        normalized.contains('ethernet') ||
        normalized.contains('internet') ||
        normalized.contains('wifi')) {
      return 'Conectividad / Red';
    }
    if (normalized.contains('proyector')) return 'Proyector / Mobiliario';
    if (normalized.contains('software') ||
        normalized.contains('licencia') ||
        normalized.contains('congel')) {
      return 'Software / Sistema Operativo';
    }
    return 'Hardware';
  }

  String _diagnosisFor(String question) {
    final normalized = question.toLowerCase();
    if (normalized.contains('red') ||
        normalized.contains('ethernet') ||
        normalized.contains('internet') ||
        normalized.contains('wifi')) {
      return '1. Verifica que el cable Ethernet esté bien conectado al equipo y al punto de red.\n2. Comprueba si el puerto muestra una luz de actividad.\n3. Desactiva y vuelve a activar el adaptador de red.\n4. Si sigue sin conexión, no cambies la configuración IP del laboratorio.';
    }
    if (normalized.contains('proyector')) {
      return '1. Confirma que el proyector esté encendido y sin cubrir sus ventilas.\n2. Revisa que el cable HDMI esté firme en ambos extremos.\n3. Selecciona la entrada correcta con el botón Source/Input.\n4. En el computador, prueba Windows + P y selecciona Duplicar.';
    }
    if (normalized.contains('software') ||
        normalized.contains('licencia') ||
        normalized.contains('congel')) {
      return '1. Espera unos segundos y evita apagar el equipo mientras guarda cambios.\n2. En Windows, presiona Ctrl + Alt + Del y abre el Administrador de tareas.\n3. Cierra solo la aplicación que no responde y vuelve a abrirla.\n4. Si aparece un error de licencia, anota el nombre del programa.';
    }
    return '1. Verifica que el cable de energía esté firme en el equipo y en el tomacorriente.\n2. Comprueba el interruptor de la regleta y el indicador de encendido.\n3. Mantén presionado el botón de encendido durante unos segundos.\n4. Si la pantalla sigue negra, no abras el equipo; registra el número de puesto.';
  }

  void _send([String? quickOption]) {
    final question = (quickOption ?? _controller.text).trim();
    if (question.isEmpty) return;
    final category = _categoryFor(question);
    setState(() {
      _selectedCategory = category;
      _messages.add(_DiagnosticMessage(text: question, isBot: false));
      _messages.add(
        _DiagnosticMessage(text: _diagnosisFor(question), isBot: true),
      );
      _showEscalation = true;
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.fieBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Asistente Virtual de Laboratorios - FIE',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                key: const Key('diagnostic-chat-list'),
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                itemCount: _messages.length + (_showEscalation ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_showEscalation && index == _messages.length) {
                    return _EscalationCard(
                      category: _selectedCategory!,
                      onCreateReport: () =>
                          widget.onCreateReport(_selectedCategory!),
                    );
                  }
                  return _MessageBubble(message: _messages[index]);
                },
              ),
            ),
            if (!_showEscalation)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Wrap(
                  spacing: 7,
                  runSpacing: 4,
                  children: [
                    for (final option in _quickOptions)
                      ActionChip(
                        key: Key('diagnostic-option-$option'),
                        label: Text(option),
                        onPressed: () => _send(option),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        side: const BorderSide(color: AppColors.line),
                        labelStyle: const TextStyle(
                          color: AppColors.fieBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            _MessageComposer(controller: _controller, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticMessage {
  const _DiagnosticMessage({required this.text, required this.isBot});

  final String text;
  final bool isBot;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _DiagnosticMessage message;

  @override
  Widget build(BuildContext context) {
    final isBot = message.isBot;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isBot
              ? isDark
                    ? const Color(0xFF25384A)
                    : const Color(0xFFEAF1F7)
              : AppColors.fieBlue,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isBot ? 4 : 14),
            bottomRight: Radius.circular(isBot ? 14 : 4),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isBot
                ? Theme.of(context).colorScheme.onSurface
                : Colors.white,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _EscalationCard extends StatelessWidget {
  const _EscalationCard({required this.category, required this.onCreateReport});

  final String category;
  final VoidCallback onCreateReport;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('diagnostic-escalation-card'),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.support_agent, color: AppColors.fieBlue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '¿El problema continúa?',
                    style: TextStyle(
                      color: AppColors.fieBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Puedes enviarlo a soporte técnico. Se preseleccionará: $category.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('create-technical-report'),
                onPressed: onCreateReport,
                icon: const Icon(Icons.post_add_outlined),
                label: const Text('Crear Reporte Técnico Ahora'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.fieBlue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('diagnostic-message-input'),
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Describe el problema...',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('send-diagnostic-message'),
              tooltip: 'Enviar mensaje',
              onPressed: onSend,
              icon: const Icon(Icons.arrow_upward),
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
