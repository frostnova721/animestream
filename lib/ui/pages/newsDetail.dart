import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/news/animenews.dart';
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
      backgroundColor: appTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: appTheme.textMainColor,
          ),
        ),
        backgroundColor: appTheme.backgroundColor,
        title: Text(
          "News",
          style: TextStyle(color: Colors.white, fontFamily: "Poppins", fontSize: 25),
        ),
      ),
      body: !loaded
          ? Center(
              child: CircularProgressIndicator(color: appTheme.accentColor),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 20, right: 20, bottom: 25, top: 25),
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
                        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return AnimatedOpacity(
                            opacity: frame == null ? 0 : 1,
                            duration: Duration(milliseconds: 200),
                            child: child,
                          );
                        },
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
