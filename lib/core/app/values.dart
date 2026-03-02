import 'dart:io';

class AppValues {
  static const _androidUserAgent = 'Mozilla/5.0 (Linux; Android 15; Pixel 9 Pro Build/AD1A.240418.003; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/124.0.6367.54 Mobile Safari/537.36';
  static const _desktopUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36';
  static final defaultClientUserAgent = Platform.isAndroid ? _androidUserAgent : _desktopUserAgent;
}
