import 'package:animestream/core/news/animenews.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class NewsDetails extends StatefulWidget {
  final String url;
  const NewsDetails({super.key, required this.url});

  @override
  State<NewsDetails> createState() => _NewsDetailsState();
}

class _NewsDetailsState extends State<NewsDetails> {
  Map<String, dynamic> news = {};
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    getDetailedNews();
  }

  Future getDetailedNews() async {
    final res = await AnimeNews().getDetaildNews(widget.url);
    if (mounted)
      setState(() {
        news = res;
        loaded = true;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !loaded
          ? Center(
              child: CircularProgressIndicator(color: themeColor),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 60,
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 20, right: 20, bottom: 25),
                    child: Text(
                      news['title'],
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Poppins",
                        fontSize: 25,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (news['image'] != null)
                    Container(
                      child: Image.network(
                        news['image'],
                      ),
                    ),
                  Container(
                    padding: EdgeInsets.only(left: 20, right: 20, top: 25),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: news['info'][0],
                            style: detailStyle(true),
                          ),
                          TextSpan(
                            text: news['info'].substring(1),
                            style: detailStyle(false),
                          )
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(bottom: 50, top: 20),
                    child: Text(
                      "credits: Anime News Network",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 194, 194, 194),
                        fontFamily: 'NunitoSans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  TextStyle detailStyle(bool bold) {
    return TextStyle(
        color: Colors.white,
        fontFamily: 'NotoSans',
        fontSize: 18,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal);
  }
}
