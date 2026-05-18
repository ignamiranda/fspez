import 'dart:async';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import '../domain/models/chat_message.dart';

class ChatBridge {
  final FlutterWebviewPlugin _webviewPlugin = FlutterWebviewPlugin();
  final _messageController = StreamController<ChatMessage>.broadcast();
  bool _isInitialized = false;

  Stream<ChatMessage> get messages => _messageController.stream;

  Future<void> initialize(String chatUrl) async {
    if (_isInitialized) return;

    _webviewPlugin.launch(
      chatUrl,
      withJavascript: true,
      withLocalStorage: true,
      hidden: true,
    );

    _webviewPlugin.onUrlChanged.listen((url) {
      if (url.contains('/chat/')) {
        _startExtraction();
      }
    });

    _isInitialized = true;
  }

  void _startExtraction() {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_messageController.isClosed) {
        timer.cancel();
        return;
      }

      try {
        final raw = await _webviewPlugin.evalJavascript('''
          (function() {
            var messages = [];
            var elements = document.querySelectorAll('[data-testid="message"]');
            elements.forEach(function(el) {
              messages.push({
                id: el.getAttribute('data-message-id') || '',
                author: (el.querySelector('[data-testid="message-author"]') || {}).textContent || '',
                body: (el.querySelector('[data-testid="message-body"]') || {}).textContent || '',
                timestamp: el.getAttribute('data-timestamp') || ''
              });
            });
            return JSON.stringify(messages);
          })();
        ''');

        if (raw is String && raw.isNotEmpty) {
          final parsed = _parseMessages(raw);
          for (final msg in parsed) {
            _messageController.add(msg);
          }
        }
      } catch (_) {}
    });
  }

  List<ChatMessage> _parseMessages(String raw) {
    // Simplified parsing — real implementation handles DOM extraction quirks
    return [];
  }

  Future<void> sendMessage(String chatId, String body) async {
    await _webviewPlugin.evalJavascript('''
      (function() {
        var input = document.querySelector('[data-testid="chat-input"]');
        if (input) {
          var nativeInputValueSetter = Object.getOwnPropertyDescriptor(
            window.HTMLInputElement.prototype, 'value'
          ).set;
          nativeInputValueSetter.call(input, '$body');
          input.dispatchEvent(new Event('input', { bubbles: true }));
          var sendBtn = document.querySelector('[data-testid="chat-send"]');
          if (sendBtn) sendBtn.click();
        }
      })();
    ''');
  }

  void dispose() {
    _messageController.close();
    _webviewPlugin.close();
    _isInitialized = false;
  }
}
