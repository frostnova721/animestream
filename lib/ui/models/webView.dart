import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/data/hive.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebView extends StatefulWidget {
  final String url;
  const WebView({super.key, required this.url});

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  String _extractToken(String url) {
    final RegExp regExp = RegExp(r'access_token=(.*?)&token_type=');
    final match = regExp.firstMatch(url);
    if (match != null) {
      final token = match.group(1);
      if (token != null) return token;
      throw new Exception("ERR_COULDNT_EXTRACT_TOKEN");
    } else {
      throw new Exception("ERR_COULDNT_EXTRACT_TOKEN");
    }
  }

  //if using flutter_inappwebview package!!!, for windows | currently no plan on doin it cus we'd have to rewrite many widgets
  // InAppWebView webview(String url) {
  //   return InAppWebView(
  //     initialUrlRequest: URLRequest(url: WebUri(url)),
  //     onLoadStart: (controller, url) {
  //         if (url!.rawValue.contains("access_token")) {
  //             storeVal("token", _extractToken(url.rawValue))
  //                 .then((value) => Navigator.of(context).pop(true));
  //           }
  //     },
  //   );
  // }

  WebViewWidget webview(String url) {
    WebViewController webViewController = WebViewController()
      ..setBackgroundColor(appTheme.backgroundColor)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url))
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (change) {
            if (change.url!.contains("access_token")) {
              storeVal("token", _extractToken(change.url!))
                  .then((value) => Navigator.of(context).pop(true));
            }
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      );
    return WebViewWidget(controller: webViewController);
  }

  @override
  Widget build(BuildContext context) {
    return webview(widget.url);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
