import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reportes_labs_espoch/screens/student/ai_support_screen.dart';
import 'package:reportes_labs_espoch/services/gemini_ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AiSupportScreen displays header, initial message and dynamic input controls', (tester) async {
    final aiService = GeminiAiService(apiKey: 'test-key');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiSupportScreen(geminiService: aiService),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verifica encabezado de Soporte Rápido con Asistente IA
    expect(find.text('Soporte rápido'), findsOneWidget);
    expect(find.textContaining('Asistente IA (Gemini)'), findsOneWidget);

    // Verifica que se muestra el mensaje inicial de bienvenida en la lista
    expect(find.textContaining('asistente técnico oficial de los laboratorios ESPOCH'), findsOneWidget);

    // Verifica controles de entrada: botón de adjuntar foto y enviar
    expect(find.byKey(const Key('ai-attach-button')), findsOneWidget);
    expect(find.byKey(const Key('ai-send-button')), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('AiSupportScreen sends message and displays in dynamic ListView', (tester) async {
    final aiService = GeminiAiService(apiKey: 'test-key');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiSupportScreen(geminiService: aiService),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Escribir mensaje en el campo de texto
    await tester.enterText(find.byType(TextField), 'Falla con el cable de red');
    await tester.pump();

    // Tocar el botón de enviar
    await tester.tap(find.byKey(const Key('ai-send-button')));
    await tester.pump();

    // Debe mostrarse el mensaje del usuario en la lista
    expect(find.text('Falla con el cable de red'), findsOneWidget);

    // Esperar a que se procese la respuesta (fallback de contingencia o API)
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Debe haber al menos 2 mensajes en la lista (bienvenida + mensaje usuario + respuesta asistente)
    expect(find.byType(SelectableText), findsAtLeastNWidgets(2));
  });
}

