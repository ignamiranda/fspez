import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ComposeWebViewScreen extends ConsumerStatefulWidget {
  final String to;
  final String subject;
  final String text;
  final String modhash;

  const ComposeWebViewScreen({
    super.key,
    required this.to,
    required this.subject,
    required this.text,
    required this.modhash,
  });

  @override
  ConsumerState<ComposeWebViewScreen> createState() => _ComposeWebViewScreenState();
}

class _ComposeWebViewScreenState extends ConsumerState<ComposeWebViewScreen> {
  bool _submitted = false;
  Timer? _timeout;
  final File _logFile = File('${Directory.systemTemp.path}\\fspez-compose.log');

  Future<void> _log(String message) async {
    try {
      await _logFile.writeAsString(
        '[${DateTime.now().toIso8601String()}] CWVS $message\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  Future<void> _onLoadStop(InAppWebViewController controller, Uri? url) async {
    await _log('onLoadStop url=$url submitted=$_submitted');
    if (_submitted) return;
    final s = url?.toString() ?? '';
    if (s.contains('/login')) {
      await _log('redirected to login - no session cookies in WebView');
      return;
    }

    _submitted = true;
    _timeout = Timer(const Duration(seconds: 15), () {
      _log('timeout');
      if (mounted) Navigator.of(context).pop(false);
    });

    try {
      await _log('evaluating JS');
      final result = await controller.callDevToolsProtocolMethod(
        methodName: 'Runtime.evaluate',
        parameters: {
          'awaitPromise': true,
          'returnByValue': true,
          'expression': '''
            (async function() {
              const modhash = ${widget.modhash.isEmpty ? '""' : ("'" + _jsEscape(widget.modhash) + "'")};
              return new Promise(function(resolve) {
                const xhr = new XMLHttpRequest();
                xhr.open('POST', 'https://www.reddit.com/api/compose');
                xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
                xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
                xhr.setRequestHeader('Accept', '*/*');
                if (modhash) xhr.setRequestHeader('X-Modhash', modhash);
                xhr.withCredentials = true;
                xhr.onload = function() { resolve({status: xhr.status, body: xhr.responseText}); };
                xhr.onerror = function() { resolve({status: 0, body: 'network error'}); };
                const fd = new URLSearchParams();
                fd.append('to', '${_jsEscape(widget.to)}');
                fd.append('subject', '${_jsEscape(widget.subject)}');
                fd.append('text', '${_jsEscape(widget.text)}');
                fd.append('uh', modhash);
                fd.append('api_type', 'json');
                xhr.send(fd.toString());
              });
            })()
          ''',
        },
      );

      await _log('result=$result');
      _timeout?.cancel();
      if (result is Map && result['result'] is Map) {
        final value = result['result']['value'];
        if (value is Map && mounted) {
          await _log('status=${value['status']}');
          Navigator.of(context).pop(value['status'] == 200);
        }
      } else if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      await _log('error=$e');
      _timeout?.cancel();
      if (mounted) Navigator.of(context).pop(false);
    }
  }

  String _jsEscape(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sending message...')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri('https://www.reddit.com/'),
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
        ),
        onLoadStop: (controller, url) => _onLoadStop(controller, url),
      ),
    );
  }
}
