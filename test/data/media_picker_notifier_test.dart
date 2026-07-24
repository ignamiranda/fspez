import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/media_picker_notifier.dart';

void main() {
  late MediaPickerNotifier notifier;

  setUp(() {
    notifier = MediaPickerNotifier();
  });

  group('initial state', () {
    test('has default values', () {
      expect(notifier.state.selectedImage, isNull);
      expect(notifier.state.selectedVideo, isNull);
      expect(notifier.state.galleryFiles, isEmpty);
      expect(notifier.state.galleryCaptions, isEmpty);
    });
  });

  group('image', () {
    test('setImage updates selectedImage', () {
      final file = PlatformFile(name: 'img.png', size: 100);
      notifier.setImage(file);
      expect(notifier.state.selectedImage, file);
    });

    test('clearImage clears selectedImage', () {
      notifier.setImage(PlatformFile(name: 'img.png', size: 100));
      notifier.clearImage();
      expect(notifier.state.selectedImage, isNull);
    });
  });

  group('video', () {
    test('setVideo updates selectedVideo', () {
      final file = PlatformFile(name: 'vid.mp4', size: 1000);
      notifier.setVideo(file);
      expect(notifier.state.selectedVideo, file);
    });

    test('clearVideo clears selectedVideo', () {
      notifier.setVideo(PlatformFile(name: 'vid.mp4', size: 1000));
      notifier.clearVideo();
      expect(notifier.state.selectedVideo, isNull);
    });
  });

  group('gallery', () {
    test('setGalleryFiles sets files and captions', () {
      final files = <PlatformFile>[
        PlatformFile(name: '1.jpg', size: 100),
        PlatformFile(name: '2.jpg', size: 200),
      ];
      notifier.setGalleryFiles(files);
      expect(notifier.state.galleryFiles, hasLength(2));
      expect(notifier.state.galleryCaptions, hasLength(2));
    });

    test('addGalleryImages caps at 20', () {
      final many = List<PlatformFile>.generate(
        20,
        (i) => PlatformFile(name: '$i.jpg', size: 100),
      );
      notifier.setGalleryFiles(many);

      notifier.addGalleryImages(
        <PlatformFile>[PlatformFile(name: 'extra.jpg', size: 100)],
      );
      expect(notifier.state.galleryFiles, hasLength(20));
    });

    test('removeGalleryItem removes file and caption', () {
      notifier.setGalleryFiles(<PlatformFile>[
        PlatformFile(name: '1.jpg', size: 100),
        PlatformFile(name: '2.jpg', size: 200),
      ]);
      notifier.removeGalleryItem(0);
      expect(notifier.state.galleryFiles, hasLength(1));
      expect(notifier.state.galleryFiles[0].name, '2.jpg');
    });

    test('reorderGallery reorders files and captions', () {
      notifier.setGalleryFiles(<PlatformFile>[
        PlatformFile(name: 'a.jpg', size: 100),
        PlatformFile(name: 'b.jpg', size: 200),
        PlatformFile(name: 'c.jpg', size: 300),
      ]);
      notifier.reorderGallery(0, 2);
      expect(notifier.state.galleryFiles[0].name, 'b.jpg');
      expect(notifier.state.galleryFiles[1].name, 'a.jpg');
      expect(notifier.state.galleryFiles[2].name, 'c.jpg');
    });

    test('updateGalleryCaption updates caption at index', () {
      notifier.setGalleryFiles([PlatformFile(name: '1.jpg', size: 100)]);
      notifier.updateGalleryCaption(0, 'New caption');
      expect(notifier.state.galleryCaptions[0], 'New caption');
    });
  });

  group('clearAllMedia', () {
    test('clears image, gallery, and video', () {
      notifier.setImage(PlatformFile(name: 'img.png', size: 100));
      notifier.setVideo(PlatformFile(name: 'vid.mp4', size: 1000));
      notifier.setGalleryFiles([PlatformFile(name: '1.jpg', size: 100)]);
      notifier.clearAllMedia();
      expect(notifier.state.selectedImage, isNull);
      expect(notifier.state.selectedVideo, isNull);
      expect(notifier.state.galleryFiles, isEmpty);
    });
  });

  group('reset', () {
    test('clears all media state', () {
      notifier.setImage(PlatformFile(name: 'img.png', size: 100));
      notifier.reset();
      expect(notifier.state.selectedImage, isNull);
      expect(notifier.state.selectedVideo, isNull);
      expect(notifier.state.galleryFiles, isEmpty);
    });
  });
}
