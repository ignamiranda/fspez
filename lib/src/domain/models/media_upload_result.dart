import 'package:equatable/equatable.dart';

/// Result of a completed media upload to Reddit.
class MediaUploadResult with Equatable {
  final String assetId;
  final String assetUrl;

  const MediaUploadResult({
    required this.assetId,
    required this.assetUrl,
  });

  @override
  List<Object?> get props => [assetId, assetUrl];
}
