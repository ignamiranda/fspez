import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaPickerState {
  final PlatformFile? selectedImage;
  final List<PlatformFile> galleryFiles;
  final List<String> galleryCaptions;
  final PlatformFile? selectedVideo;

  const MediaPickerState({
    this.selectedImage,
    this.galleryFiles = const [],
    this.galleryCaptions = const [],
    this.selectedVideo,
  });

  MediaPickerState copyWith({
    PlatformFile? selectedImage,
    List<PlatformFile>? galleryFiles,
    List<String>? galleryCaptions,
    PlatformFile? selectedVideo,
    bool clearImage = false,
    bool clearGallery = false,
    bool clearVideo = false,
  }) {
    return MediaPickerState(
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
      galleryFiles:
          clearGallery ? const [] : (galleryFiles ?? this.galleryFiles),
      galleryCaptions:
          clearGallery ? const [] : (galleryCaptions ?? this.galleryCaptions),
      selectedVideo: clearVideo ? null : (selectedVideo ?? this.selectedVideo),
    );
  }
}

class MediaPickerNotifier extends StateNotifier<MediaPickerState> {
  MediaPickerNotifier() : super(const MediaPickerState());

  void setImage(PlatformFile? file) {
    state = state.copyWith(selectedImage: file);
  }

  void clearImage() {
    state = state.copyWith(clearImage: true);
  }

  void setGalleryFiles(List<PlatformFile> files) {
    state = state.copyWith(
      galleryFiles: files,
      galleryCaptions: List.filled(files.length, ''),
    );
  }

  void addGalleryImages(List<PlatformFile> files) {
    final combined = [...state.galleryFiles, ...files];
    if (combined.length > 20) return;
    state = state.copyWith(
      galleryFiles: combined,
      galleryCaptions: [
        ...state.galleryCaptions,
        ...List.filled(files.length, ''),
      ],
    );
  }

  void reorderGallery(int oldIndex, int newIndex) {
    final files = List<PlatformFile>.from(state.galleryFiles);
    final captions = List<String>.from(state.galleryCaptions);
    if (newIndex > oldIndex) newIndex -= 1;
    final file = files.removeAt(oldIndex);
    final caption = captions.removeAt(oldIndex);
    files.insert(newIndex, file);
    captions.insert(newIndex, caption);
    state = state.copyWith(galleryFiles: files, galleryCaptions: captions);
  }

  void removeGalleryItem(int index) {
    final files = List<PlatformFile>.from(state.galleryFiles)..removeAt(index);
    final captions = List<String>.from(state.galleryCaptions)..removeAt(index);
    state = state.copyWith(galleryFiles: files, galleryCaptions: captions);
  }

  void updateGalleryCaption(int index, String caption) {
    final captions = List<String>.from(state.galleryCaptions);
    if (index < captions.length) {
      captions[index] = caption;
      state = state.copyWith(galleryCaptions: captions);
    }
  }

  void setVideo(PlatformFile? file) {
    state = state.copyWith(selectedVideo: file);
  }

  void clearVideo() {
    state = state.copyWith(clearVideo: true);
  }

  void clearAllMedia() {
    state =
        state.copyWith(clearImage: true, clearGallery: true, clearVideo: true);
  }

  void reset() {
    state = const MediaPickerState();
  }
}
