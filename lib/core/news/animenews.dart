import "package:http/http.dart";
import "package:html/parser.dart" as html;

class AnimeNews {
  final String _baseUrl = 'https://animenewsnetwork.com';

  final String _cdnUrl = 'https://cdn.animenewsnetwork.com';

  Future<Map<String, String?>> getDetailedNews(String url) async {
    final res = await fetch(url);
    final document = html.parse(res);
    final pageTitle = document.querySelector("div#page-title > h1#page_header")?.text.replaceAll(RegExp(r'News'), '').replaceAll(r'\n| {2,}', '').trim();
    final postedOn = document.querySelector('div#page-title > small')?.text.trim();
    final postedBy = document.querySelector('div#page-title')?.text.replaceAll(RegExp(r'n| {2,}'), '').split('by')[1].trim();
    final captions = document.querySelectorAll('figcaption');
    for(final caption in captions) {
      caption.remove();
    }
    final details = document.querySelector('div.text-zone.easyread-width > div.KonaBody > div.meat');
    final image = details?.querySelector('figure > img')?.attributes['data-src'] != null ? _cdnUrl + (details?.querySelector('figure > img')?.attributes['data-src'] ?? '') : null;
    final List<String> texts = [];
    details?.children.forEach((element) { 
      texts.add(element.text.trim());
    }); 
    return {
        'title': pageTitle,
        'postedOn': postedOn,
        'postedBy': postedBy,
        'image': image,
        'info': texts.join()
    };
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
        'snippet': snippet
      });
    });

    return newses;
  }

  Future<String> fetch(String url) async {
    final res = await get(Uri.parse(url));
    return res.body;
  }
}