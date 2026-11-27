import "package:animestream/core/network/network.dart";
import "package:animestream/core/news/detailedAnimeNews.dart";
import "package:html/dom.dart";
import "package:html/parser.dart" as html;

class AnimeNews {
  final String _baseUrl = 'https://animenewsnetwork.com';

  final String _cdnUrl = 'https://cdn.animenewsnetwork.com';

  static const _inlineTags = {'cite', 'a', 'em', 'i', 'b', 'strong', 'span', 'u', 'sup', 'sub', 'small', 'abbr'};

  Future<DetailedAnimeNews> getDetailedNews(String url) async {
    final res = await fetch(url);
    final document = html.parse(res);
    final pageTitle = document
        .querySelector("div#page-title > h1#page_header")
        ?.text
        .replaceAll(RegExp(r'News'), '')
        .replaceAll(r'\n| {2,}', '')
        .trim();
    final postedOn = document.querySelector('div#page-title > small')?.text.trim();
    final postedBy = document
        .querySelector('div#page-title')
        ?.text
        .replaceAll(RegExp(r'n| {2,}'), '')
        .split('by')[1]
        .trim();
    final captions = document.querySelectorAll('figcaption');
    for (final caption in captions) {
      caption.remove();
    }
    final details = document.querySelector('div.text-zone.easyread-width > div.KonaBody > div.meat');
    final image = details?.querySelector('img')?.attributes['src'] != null
        ? _cdnUrl + (details?.querySelector('img')?.attributes['src'] ?? '')
        : null;
    final List<String> texts = [];
    // Walk nodes (not children) so bare text between inline tags like <cite> isn't dropped.
    // Consecutive inline content is merged into one paragraph; block elements stay separate.
    final inlineBuffer = StringBuffer();
    void flushInline() {
      final text = inlineBuffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isNotEmpty) texts.add(text);
      inlineBuffer.clear();
    }

    for (final node in details?.nodes ?? const <Node>[]) {
      if (node is Text) {
        inlineBuffer.write(node.text);
      } else if (node is Element) {
        final tag = node.localName;
        if (tag == 'br') {
          flushInline();
        } else if (_inlineTags.contains(tag)) {
          inlineBuffer.write(node.text);
        } else {
          flushInline();
          final text = node.text.trim();
          if (text.isNotEmpty) texts.add(text);
        }
      }
    }
    flushInline();
    return DetailedAnimeNews(
      title: pageTitle ?? "Unknown",
      postedOn: postedOn ?? "Unknown",
      postedBy: postedBy ?? "Unknown",
      image: image,
      info: texts,
    );
  }

  Future<List<Map<String, String?>>> getNewses() async {
    final url = _baseUrl + '/news';
    final res = await fetch(url);
    final document = html.parse(res);
    final List<Map<String, String?>> newses = [];
    document.querySelectorAll('.herald.box.news.t-news').forEach((element) {
      final src = element.querySelector('.thumbnail')?.attributes['data-src'];
      final image = src != null ? _cdnUrl + src : null;
      final wrapDiv = element.querySelector('.wrap > div');
      final titleElement = wrapDiv?.querySelector('h3')?.children[0] ?? null;
      final ref = titleElement?.attributes['href'] != null ? url + (titleElement?.attributes['href'] ?? '') : null;
      final title = titleElement?.text.trim();
      final dateAndTime = wrapDiv?.querySelector('time')?.attributes['datetime'];
      final dateSplit = dateAndTime?.split('T')[0].split('-');
      final date = "${dateSplit?[2] ?? null}-${dateSplit?[1] ?? null}-${dateSplit?[0] ?? null}";
      final time = dateAndTime?.split('T')[1].split(RegExp(r'\+|\-'))[0];
      final topic = wrapDiv?.querySelector('.topics > a')?.attributes['topic'];
      final snippet = wrapDiv?.querySelector('.snippet > span.full')?.text;
      newses.add({
        'image': image,
        'title': title,
        'url': ref,
        'date': date,
        'time': time,
        'category': topic,
        'snippet': snippet,
      });
    });

    return newses;
  }

  Future<String> fetch(String url) async {
    final res = await get(Uri.parse(url), cacheDuration: const Duration(minutes: 5));
    return res.body;
  }
}
