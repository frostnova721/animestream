import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class HttpRequestInfo {
  final Uri url;
  const HttpRequestInfo(this.url);
}

class HttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String body;
  final Uint8List bodyBytes;
  final String? reasonPhrase;
  final HttpRequestInfo? request;
  final bool cached;

  HttpResponse(
    this.statusCode,
    this.body, {
    Map<String, String>? headers,
    Uint8List? bodyBytes,
    this.reasonPhrase,
    this.request,
    this.cached = false,
  })  : headers = headers ?? {},
        bodyBytes = bodyBytes ?? Uint8List.fromList(utf8.encode(body));

  dynamic get json {
    if (statusCode < 200 || statusCode >= 300) {
      throw HttpException('HTTP $statusCode: $body');
    }
    if (body.trimLeft().startsWith('<')) {
      throw Exception(
        'Expected JSON but received HTML (status $statusCode). '
        'The server may be behind a Cloudflare challenge.',
      );
    }
    return jsonDecode(body);
  }
}

typedef Response = HttpResponse;
