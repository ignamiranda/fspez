import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/enums/media_type.dart';
import 'gallery_saver.dart';

sealed class SaveResult {}

class SaveSuccess extends SaveResult {}

class SaveFailure extends SaveResult {
  final String message;
  SaveFailure(this.message);
}

class MediaSaveService {
  final http.Client _httpClient;
  final GallerySaver _gallerySaver;

  MediaSaveService({
    required http.Client httpClient,
    required GallerySaver gallerySaver,
  })  : _httpClient = httpClient,
        _gallerySaver = gallerySaver;

  Future<SaveResult> saveMedia(String url, MediaType type) async {
    final filename = _extractFilename(url);
    if (filename == null) {
      return SaveFailure('Could not extract filename from URL');
    }

    late Uint8List bytes;
    try {
      final response = await _httpClient.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return SaveFailure('Server returned status ${response.statusCode}');
      }
      bytes = response.bodyBytes;
    } catch (e) {
      return SaveFailure(_userFriendlyMessage(e));
    }

    try {
      final saved = switch (type) {
        MediaType.image =>
          await _gallerySaver.saveImage(bytes, name: filename, quality: 100),
        MediaType.video => await _saveVideo(bytes, filename),
      };

      if (saved) return SaveSuccess();
      return SaveFailure('Failed to save to gallery');
    } catch (e) {
      return SaveFailure(_userFriendlyMessage(e));
    }
  }

  void dispose() {
    _httpClient.close();
  }

  Future<bool> _saveVideo(Uint8List bytes, String filename) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/$filename');
    await tempFile.writeAsBytes(bytes);
    try {
      return await _gallerySaver.saveFile(tempFile.path, name: filename);
    } finally {
      await tempFile.delete();
    }
  }

  String? _extractFilename(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      if (path.isEmpty || path == '/') return null;
      final segments = path.split('/');
      if (segments.isEmpty) return null;
      final last = segments.last;
      if (last.isEmpty) return null;
      return last;
    } catch (_) {
      return null;
    }
  }

  String _userFriendlyMessage(Object error) {
    if (error is SocketException) {
      return 'Could not connect to the server. Check your connection.';
    }
    if (error is HttpException) {
      return 'Could not connect to the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
