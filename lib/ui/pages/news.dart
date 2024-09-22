import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/news/animenews.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/pages/newsDetail.dart';
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
      backgroundColor: appTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_rounded,
          color: appTheme.textMainColor,),
        ),
        backgroundColor: appTheme.backgroundColor,
        title: Text(
          "News",
          style: TextStyle(color: appTheme.textMainColor, fontFamily: "Poppins", fontSize: 25),
        ),
      ),
      body: !loaded
          ? Center(
              child: CircularProgressIndicator(
                color: appTheme.accentColor,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: MediaQuery.of(context).padding.copyWith(top: 10),
                child: Column(
                  children: [
                    // Container(
                    //   padding: EdgeInsets.only(top: 10, bottom: MediaQuery.of(context).padding.bottom),
                    //   child: Text(
                    //     "News",
                    //     style: TextStyle(
                    //         color: Colors.white,
                    //         fontFamily: "Poppins",
                    //         fontSize: 30),
                    // ),
                    // ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: newses.length,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => NewsDetails(
                                    url: newses[index]['url'],
                                  )));
                        },
                        child: Container(
                          decoration: BoxDecoration(color: Colors.transparent),
                          padding: EdgeInsets.only(top: 5, left: 10, right: 10),
                          child: Cards().NewsCard(newses[index]['title'], newses[index]['image'], newses[index]['date'],
                              newses[index]['time']),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
