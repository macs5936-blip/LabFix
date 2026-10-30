import 'package:flutter_test/flutter_test.dart';
import 'package:reportes_labs_espoch/services/gemini_ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeminiAiService Unit Tests', () {
    test('Initializes with default LabFix API key and official ESPOCH system instruction', () {
      final service = GeminiAiService();

      expect(GeminiAiService.defaultApiKey, 'AQ.Ab8RN6Ksd3ArsqVAULUNHuBHu0SF0MnxJcWlNVKHAZPZyHnxwA');
      expect(GeminiAiService.defaultModelName, 'gemini-1.5-flash');
      expect(GeminiAiService.systemInstruction, contains('asistente técnico oficial'));
      expect(GeminiAiService.systemInstruction, contains('ESPOCH'));
      expect(service.model, isNotNull);
      expect(service.chatSession, isNotNull);
    });

    test('sendMessage rethrows error when an invalid key is provided without simulated fallback', () async {
      final service = GeminiAiService(apiKey: 'invalid-dummy-key');

      expect(
        () => service.sendMessage(prompt: 'Prueba de falla directa'),
        throwsA(isA<Exception>()),
      );
    });

    test('resetSession restarts the chat session without throwing', () {
      final service = GeminiAiService();
      expect(() => service.resetSession(), returnsNormally);
    });
  });
}
