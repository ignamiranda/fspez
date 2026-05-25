import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ComposeAutotestScreen extends StatefulWidget {
  final String sessionValue;

  const ComposeAutotestScreen({super.key, required this.sessionValue});

  @override
  State<ComposeAutotestScreen> createState() => _ComposeAutotestScreenState();
}

class _ComposeAutotestScreenState extends State<ComposeAutotestScreen> {
  final File _logFile = File('${Directory.systemTemp.path}\\fspez-compose.log');
  bool _cdpPrimed = false;

  Future<void> _log(String message) async {
    try {
      await _logFile.writeAsString(
        '[${DateTime.now().toIso8601String()}] AUTOTEST $message\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  Future<void> _attemptCompose(InAppWebViewController controller) async {
    Timer(const Duration(seconds: 20), () {
      _log('timeout');
      if (mounted) exit(1);
    });

    try {
      final result = await controller.callDevToolsProtocolMethod(
        methodName: 'Runtime.evaluate',
        parameters: {
          'awaitPromise': true,
          'returnByValue': true,
          'expression': '''
            (async function() {
              const wait = ms => new Promise(r => setTimeout(r, ms));
              for (let i = 0; i < 20; i++) {
                const form = document.querySelector('form[action*="compose"], form[action*="api/compose"], [data-testid="compose-form"], form:has(input[name="to"])');
                if (form) break;
                await wait(500);
              }
              const allForms = Array.from(document.querySelectorAll('form'));
              return JSON.stringify({
                title: document.title,
                loggedIn: document.querySelector('[user-logged-in]')?.getAttribute('user-logged-in'),
                formCount: allForms.length,
                forms: allForms.map(f => ({
                  id: f.id,
                  action: f.action.substring(0, 100),
                  method: f.method,
                  inputs: Array.from(f.querySelectorAll('input, textarea, button')).map(i => ({
                    type: i.type || i.tagName,
                    name: i.name,
                    placeholder: (i.placeholder || '').substring(0, 50),
                    className: (i.className || '').toString().substring(0, 80),
                  })),
                })),
                composeElements: (function() {
                  const allElements = document.querySelectorAll('input, textarea, button');
                  const results = [];
                  allElements.forEach(el => {
                    const html = el.outerHTML.substring(0, 200);
                    if (html.includes('ompose') || html.includes('message') || html.includes('recipient') || html.includes('subject') || html.includes('to') || html.includes('send') || html.includes('submit')) {
                      results.push(html);
                    }
                  });
                  return results;
                })(),
              });
            })()
          ''',
        },
      );
      final str = result is Map
          ? (result['result'] is Map
              ? (result['result']['value'] as String? ?? '')
              : '')
          : '';
      await _log('page inspect: ${str.substring(0, str.length.clamp(0, 6000))}');
      exit(1);
    } catch (e) {
      await _log('error=$e');
      exit(1);
    }
  }

  Future<void> _onLoadStop(InAppWebViewController controller, Uri? url) async {
    await _log('load url=$url');
    if (url == null) return;
    final s = url.toString();
    if (!s.contains('reddit.com')) return;
    if (s.contains('/login')) {
      await _log('redirected to login');
      exit(1);
    }

    if (!_cdpPrimed) {
      _cdpPrimed = true;
      final setResult = await controller.callDevToolsProtocolMethod(
        methodName: 'Network.setCookie',
        parameters: {
          'name': 'reddit_session',
          'value': widget.sessionValue,
          'url': 'https://www.reddit.com/',
          'path': '/',
          'secure': true,
          'httpOnly': true,
        },
      );
      await _log('cdp setCookie=$setResult');
      await controller.loadUrl(
        urlRequest: URLRequest(
          url: WebUri('https://www.reddit.com/message/compose/'),
        ),
      );
      return;
    }

    if (s.contains('/message/compose/') && !s.contains('/login')) {
      await _attemptCompose(controller);
    }
  }

  @override
  void initState() {
    super.initState();
    _logFile.writeAsString('', mode: FileMode.write);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compose autotest')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri('https://www.reddit.com/'),
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
        ),
        onLoadStop: _onLoadStop,
      ),
    );
  }
}
