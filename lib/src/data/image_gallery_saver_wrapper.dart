import 'dart:typed_data';

import 'package:image_gallery_saver/image_gallery_saver.dart';

import 'gallery_saver.dart';

class ImageGallerySaverWrapper implements GallerySaver {
  const ImageGallerySaverWrapper();
  @override
  Future<bool> saveImage(Uint8List bytes, {String? name, int? quality}) async {
    final result = await ImageGallerySaver.saveImage(bytes,
        name: name, quality: quality ?? 100);
    return result?['isSuccess'] == true;
  }

  @override
  Future<bool> saveFile(String filePath, {String? name}) async {
    final result = await ImageGallerySaver.saveFile(filePath, name: name);
    return result?['isSuccess'] == true;
  }
}
