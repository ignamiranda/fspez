import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void openUrl(String url) {
  final browser = InAppBrowser();
  browser.openUrlRequest(
    urlRequest: URLRequest(url: WebUri(url)),
  );
}
