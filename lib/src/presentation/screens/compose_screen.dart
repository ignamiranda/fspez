import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_providers.dart';
import '../../data/write_providers.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  final String? replyTo;
  final String? replySubject;

  const ComposeScreen({super.key, this.replyTo, this.replySubject});

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.replyTo != null) {
      _toController.text = widget.replyTo!;
      _toController.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.replyTo!.length),
      );
    }
    if (widget.replySubject != null) {
      _subjectController.text = widget.replySubject!;
    }
  }

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final to = _toController.text.trim();
    final subject = _subjectController.text.trim();
    final text = _textController.text.trim();
    final account = ref.read(activeAccountProvider);
    if (to.isEmpty || subject.isEmpty || text.isEmpty || account == null) {
      return;
    }

    final cookie = account.sessionCookie;
    if (cookie.rawCookie == null || cookie.modhash == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Re-login required to send messages')),
        );
      }
      return;
    }

    final success = await ref.read(composeProvider.notifier).send(
      fields: {
        'to': to,
        'subject': subject,
        'text': text,
        'uh': cookie.modhash ?? '',
        'api_type': 'json',
      },
      sessionCookie: cookie,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      final state = ref.read(composeProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compose failed: ${state.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(activeAccountProvider);
    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compose')),
        body: const Center(child: Text('Log in to send messages.')),
      );
    }

    final composeState = ref.watch(composeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
        actions: [
          if (composeState.isProcessing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _send,
              child: const Text('Send'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _toController,
            decoration: const InputDecoration(
              labelText: 'To',
              hintText: 'username',
              border: OutlineInputBorder(),
              prefixText: 'u/',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
            ),
            maxLines: 10,
            minLines: 5,
          ),
        ],
      ),
    );
  }
}
