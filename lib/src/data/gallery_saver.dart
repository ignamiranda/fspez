import 'dart:typed_data';

abstract class GallerySaver {
  Future<bool> saveImage(Uint8List bytes, {String? name, int? quality});
  Future<bool> saveFile(String filePath, {String? name});
}
