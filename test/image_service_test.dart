import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reportes_labs_espoch/services/image_service.dart';

void main() {
  group('ImageService (ImgBB API)', () {
    test('uploads image bytes and extracts data.url successfully', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          contains('https://api.imgbb.com/1/upload'),
        );
        expect(
          request.url.queryParameters['key'],
          '45abdbd819a9d555391431aae885365f',
        );
        expect(request.method, 'POST');

        final responseBody = jsonEncode({
          'data': {
            'id': 'abc1234',
            'title': 'evidence',
            'url_viewer': 'https://ibb.co/abc1234',
            'url': 'https://i.ibb.co/xyz987/evidence.jpg',
            'display_url': 'https://i.ibb.co/xyz987/evidence.jpg',
          },
          'success': true,
          'status': 200,
        });

        return http.Response(responseBody, 200);
      });

      final service = ImageService(client: mockClient);
      final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final url = await service.uploadImageBytes(
        dummyBytes,
        fileName: 'evidence.jpg',
      );

      expect(url, 'https://i.ibb.co/xyz987/evidence.jpg');
    });

    test('throws exception when status code is not 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status_code': 400,
            'error': {'message': 'Invalid API Key'},
          }),
          400,
        );
      });

      final service = ImageService(client: mockClient);
      final dummyBytes = Uint8List.fromList([1, 2, 3]);

      expect(
        () => service.uploadImageBytes(dummyBytes),
        throwsA(isA<Exception>()),
      );
    });
  });
}

