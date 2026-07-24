import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/gallery_saver.dart';
import 'package:fspez/src/data/media_save_service.dart';
import 'package:fspez/src/domain/enums/media_type.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

class _MockGallerySaver extends Mock implements GallerySaver {}

void main() {
  late _MockHttpClient httpClient;
  late _MockGallerySaver gallerySaver;
  late MediaSaveService service;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    httpClient = _MockHttpClient();
    gallerySaver = _MockGallerySaver();
    service = MediaSaveService(
      httpClient: httpClient,
      gallerySaver: gallerySaver,
    );
  });

  group('saveMedia', () {
    const imageUrl = 'https://i.redd.it/abc123.jpg';
    const videoUrl = 'https://v.redd.it/def456/HLSPlaylist.m3u8?fallback=1';

    test('downloads and saves an image successfully', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      when(() => httpClient.get(Uri.parse(imageUrl))).thenAnswer(
        (_) async => http.Response.bytes(bytes, 200),
      );
      when(() => gallerySaver.saveImage(
            any(),
            name: any(named: 'name'),
            quality: any(named: 'quality'),
          )).thenAnswer((_) async => true);

      final result = await service.saveMedia(imageUrl, MediaType.image);

      expect(result, isA<SaveSuccess>());
      verify(() => gallerySaver.saveImage(
            bytes,
            name: 'abc123.jpg',
            quality: 100,
          )).called(1);
    });

    test('downloads and saves a video successfully', () async {
      final bytes = Uint8List.fromList([4, 5, 6]);
      when(() => httpClient.get(Uri.parse(videoUrl))).thenAnswer(
        (_) async => http.Response.bytes(bytes, 200),
      );
      when(() => gallerySaver.saveFile(
            any(),
            name: any(named: 'name'),
          )).thenAnswer((_) async => true);

      final result = await service.saveMedia(videoUrl, MediaType.video);

      expect(result, isA<SaveSuccess>());
      verify(() => gallerySaver.saveFile(
            any(),
            name: 'HLSPlaylist.m3u8',
          )).called(1);
    });

    test('returns failure on HTTP error', () async {
      when(() => httpClient.get(Uri.parse(imageUrl))).thenAnswer(
        (_) async => http.Response.bytes(Uint8List.fromList([]), 404),
      );

      final result = await service.saveMedia(imageUrl, MediaType.image);

      expect(result, isA<SaveFailure>());
      expect((result as SaveFailure).message, contains('404'));
      verifyNever(
          () => gallerySaver.saveImage(any(), name: any(named: 'name')));
    });

    test('returns failure on network error', () async {
      when(() => httpClient.get(Uri.parse(imageUrl)))
          .thenThrow(const SocketException('Connection refused'));

      final result = await service.saveMedia(imageUrl, MediaType.image);

      expect(result, isA<SaveFailure>());
      verifyNever(
          () => gallerySaver.saveImage(any(), name: any(named: 'name')));
    });

    test('returns failure when gallery save fails', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      when(() => httpClient.get(Uri.parse(imageUrl))).thenAnswer(
        (_) async => http.Response.bytes(bytes, 200),
      );
      when(() => gallerySaver.saveImage(
            any(),
            name: any(named: 'name'),
            quality: any(named: 'quality'),
          )).thenAnswer((_) async => false);

      final result = await service.saveMedia(imageUrl, MediaType.image);

      expect(result, isA<SaveFailure>());
    });

    test('returns failure when gallery save throws', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      when(() => httpClient.get(Uri.parse(imageUrl))).thenAnswer(
        (_) async => http.Response.bytes(bytes, 200),
      );
      when(() => gallerySaver.saveImage(
            any(),
            name: any(named: 'name'),
            quality: any(named: 'quality'),
          )).thenThrow(PlatformException(code: 'save_failed'));

      final result = await service.saveMedia(imageUrl, MediaType.image);

      expect(result, isA<SaveFailure>());
    });

    test('extracts filename from URL', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      const urlWithQuery = 'https://preview.redd.it/xyz789.png?width=640';
      when(() => httpClient.get(Uri.parse(urlWithQuery))).thenAnswer(
        (_) async => http.Response.bytes(bytes, 200),
      );
      when(() => gallerySaver.saveImage(
            any(),
            name: any(named: 'name'),
            quality: any(named: 'quality'),
          )).thenAnswer((_) async => true);

      await service.saveMedia(urlWithQuery, MediaType.image);

      verify(() => gallerySaver.saveImage(
            bytes,
            name: 'xyz789.png',
            quality: 100,
          )).called(1);
    });
  });
}
