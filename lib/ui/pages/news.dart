import 'package:animestream/core/news/animenews.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/pages/newsDetail.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class News extends StatefulWidget {
  const News({super.key});

  @override
  State<News> createState() => _NewsState();
}

class _NewsState extends State<News> {
  List newses = [];
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    getNewses();
  }

  Future getNewses() async {
    final List<dynamic> data = await AnimeNews().getNewses();
    if (mounted) {
      setState(() {
        newses = data;
        loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !loaded
          ? Center(
            child: CircularProgressIndicator(
                color: themeColor,
              ),
          )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 50,
                  ),
                  Container(
                    child: Text(
                      "News",
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: "Poppins",
                          fontSize: 22),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: newses.length,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => NewsDetails(url: newses[index]['url'],)));
                      },
                      child: Container(
                        decoration: BoxDecoration(color: Colors.black),
                        padding: EdgeInsets.only(top: 5, left: 10, right: 10),
                        child: NewsCard(
                            newses[index]['title'],
                            newses[index]['image'],
                            newses[index]['date'],
                            newses[index]['time']),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
