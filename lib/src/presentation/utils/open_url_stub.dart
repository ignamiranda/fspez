// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
// dart:html is required for Flutter web URL opening — only compiled on web via conditional export.
import 'dart:html' as html;

void openUrl(String url) {
  html.window.open(url, '_blank');
}
