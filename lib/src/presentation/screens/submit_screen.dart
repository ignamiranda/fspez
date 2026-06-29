import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/auth_providers.dart';
import '../../data/write_providers.dart';
import '../widgets/subreddit_rules_sheet.dart';

class SubmitScreen extends ConsumerStatefulWidget {
  final String? subreddit;

  const SubmitScreen({super.key, this.subreddit});

  @override
  ConsumerState<SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends ConsumerState<SubmitScreen>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final _urlController = TextEditingController();
  final _subredditController = TextEditingController();
  late final TabController _tabController;

  // Image tab state
  PlatformFile? _selectedImage;
  File? _imageFile;

  // Gallery tab state
  List<PlatformFile> _galleryFiles = [];
  final List<TextEditingController> _captionControllers = [];

  // Video tab state
  PlatformFile? _selectedVideo;
  File? _videoFile;

  bool get _hasSubreddit => _subredditController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    if (widget.subreddit != null) {
      _subredditController.text = widget.subreddit!;
    }
    _subredditController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _urlController.dispose();
    _subredditController.dispose();
    _tabController.dispose();
    for (final c in _captionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSubmit {
    final title = _titleController.text.trim();
    final subreddit = _subredditController.text.trim();
    if (title.isEmpty || subreddit.isEmpty) return false;
    switch (_tabController.index) {
      case 0: // Text
      case 1: // Link
        return true;
      case 2: // Image
        return _selectedImage != null;
      case 3: // Gallery
        return _galleryFiles.isNotEmpty;
      case 4: // Video
        return _selectedVideo != null;
      default:
        return false;
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedImage = result.files.first;
        _imageFile =
            _selectedImage!.path != null ? File(_selectedImage!.path!) : null;
      });
    }
  }

  Future<void> _pickGalleryImages() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (result.files.length > 20) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 20 images allowed')),
      );
      return;
    }
    setState(() {
      _galleryFiles = result.files;
      _rebuildCaptionControllers();
    });
  }

  void _addMoreGalleryImages(FilePickerResult result) {
    if (!mounted) return;
    final combined = [..._galleryFiles, ...result.files];
    if (combined.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 20 images allowed')),
      );
      return;
    }
    setState(() {
      final existingCount = _galleryFiles.length;
      _galleryFiles = combined;
      for (var i = existingCount; i < _galleryFiles.length; i++) {
        _captionControllers.add(TextEditingController());
      }
    });
  }

  void _removeGalleryItem(int index) {
    setState(() {
      _captionControllers[index].dispose();
      _captionControllers.removeAt(index);
      _galleryFiles.removeAt(index);
    });
  }

  void _rebuildCaptionControllers() {
    for (final c in _captionControllers) {
      c.dispose();
    }
    _captionControllers.clear();
    for (var i = 0; i < _galleryFiles.length; i++) {
      _captionControllers.add(TextEditingController());
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedVideo = result.files.first;
        _videoFile =
            _selectedVideo!.path != null ? File(_selectedVideo!.path!) : null;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageFile = null;
    });
  }

  void _removeVideo() {
    setState(() {
      _selectedVideo = null;
      _videoFile = null;
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final subreddit = _subredditController.text.trim();
    final account = ref.read(activeAccountProvider);
    if (title.isEmpty || subreddit.isEmpty || account == null) return;

    bool success;
    switch (_tabController.index) {
      case 0: // Text
        final fields = <String, String>{
          'kind': 'self',
          'sr': subreddit,
          'title': title,
          'uh': account.sessionCookie.modhash ?? '',
        };
        if (_textController.text.trim().isNotEmpty) {
          fields['text'] = _textController.text.trim();
        }
        success = await ref.read(submitProvider.notifier).submit(
              fields: fields,
              sessionCookie: account.sessionCookie,
            );
        break;
      case 1: // Link
        final fields = <String, String>{
          'kind': 'link',
          'sr': subreddit,
          'title': title,
          'uh': account.sessionCookie.modhash ?? '',
        };
        if (_urlController.text.trim().isNotEmpty) {
          fields['url'] = _urlController.text.trim();
        }
        success = await ref.read(submitProvider.notifier).submit(
              fields: fields,
              sessionCookie: account.sessionCookie,
            );
        break;
      case 2: // Image
        if (_selectedImage == null || _selectedImage!.path == null) return;
        {
          final bytes = await File(_selectedImage!.path!).readAsBytes();
          success = await ref.read(submitProvider.notifier).submitImage(
                title: title,
                subreddit: subreddit,
                imageBytes: bytes,
                imageFilename: _selectedImage!.name,
                sessionCookie: account.sessionCookie,
              );
        }
        break;
      case 3: // Gallery
        if (_galleryFiles.isEmpty) return;
        {
          final items =
              <({Uint8List bytes, String filename, String caption})>[];
          for (var i = 0; i < _galleryFiles.length; i++) {
            final f = _galleryFiles[i];
            if (f.path == null) continue;
            final bytes = await File(f.path!).readAsBytes();
            items.add((
              bytes: bytes,
              filename: f.name,
              caption: _captionControllers[i].text.trim(),
            ));
          }
          if (items.isEmpty) return;
          success = await ref.read(submitProvider.notifier).submitGallery(
                title: title,
                subreddit: subreddit,
                items: items,
                sessionCookie: account.sessionCookie,
              );
        }
        break;
      case 4: // Video
        if (_selectedVideo == null || _selectedVideo!.path == null) return;
        {
          final bytes = await File(_selectedVideo!.path!).readAsBytes();
          success = await ref.read(submitProvider.notifier).submitVideo(
                title: title,
                subreddit: subreddit,
                videoBytes: bytes,
                videoFilename: _selectedVideo!.name,
                sessionCookie: account.sessionCookie,
              );
        }
        break;
      default:
        return;
    }

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post submitted'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      final state = ref.read(submitProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: ${state.error}')),
      );
    }
  }

  void _showRules() {
    final subreddit = _subredditController.text.trim();
    if (subreddit.isEmpty) return;
    showSubredditRulesSheet(context, subredditName: subreddit);
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(submitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Text'),
            Tab(text: 'Link'),
            Tab(text: 'Image'),
            Tab(text: 'Gallery'),
            Tab(text: 'Video'),
          ],
        ),
        actions: [
          if (submitState.isSubmitting)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _canSubmit ? _submit : null,
              child: const Text('Submit'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _subredditController,
                  decoration: const InputDecoration(
                    labelText: 'Subreddit',
                    hintText: 'subreddit_name',
                    border: OutlineInputBorder(),
                    prefixText: 'r/',
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _hasSubreddit ? _showRules : null,
                    icon: const Icon(Icons.rule_outlined),
                    label: const Text('View community rules'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Text tab — identical to existing
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: 'Text (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 8,
                  ),
                ),
                // Link tab — identical to existing
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      hintText: 'https://...',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ),
                // Image tab
                _buildImageTab(),
                // Gallery tab
                _buildGalleryTab(),
                // Video tab
                _buildVideoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageTab() {
    if (_selectedImage == null || _imageFile == null) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image_outlined),
          label: const Text('Pick Image'),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _imageFile!,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Text(_selectedImage!.name,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Change'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _removeImage,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    if (_galleryFiles.isEmpty) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: _pickGalleryImages,
          icon: const Icon(Icons.collections_outlined),
          label: const Text('Pick Images'),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < _galleryFiles.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _buildGalleryItem(i),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final result = await FilePicker.pickFiles(
                type: FileType.image,
                allowMultiple: true,
              );
              if (result != null && result.files.isNotEmpty) {
                _addMoreGalleryImages(result);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add more'),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryItem(int index) {
    final file = _galleryFiles[index];
    final filePath = file.path;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            if (filePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(filePath),
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _captionControllers[index],
              decoration: const InputDecoration(
                hintText: 'Caption (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _removeGalleryItem(index),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTab() {
    if (_selectedVideo == null || _videoFile == null) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: _pickVideo,
          icon: const Icon(Icons.videocam_outlined),
          label: const Text('Pick Video'),
        ),
      );
    }
    final sizeBytes = _selectedVideo!.size;
    final sizeMb = sizeBytes / (1024 * 1024);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.videocam, size: 80, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_selectedVideo!.name,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('${sizeMb.toStringAsFixed(1)} MB',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Change'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _removeVideo,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
