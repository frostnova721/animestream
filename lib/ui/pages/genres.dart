import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/database/anilist/queries.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class GenresPage extends StatefulWidget {
  const GenresPage({super.key});

  @override
  State<GenresPage> createState() => _GenresPageState();
}

class _GenresPageState extends State<GenresPage> {
  final List<String> genres = [
    "Action",
    "Adventure",
    "Comedy",
    "Drama",
    "Ecchi",
    "Fantasy",
    "Horror",
    "Mahou Shoujo",
    "Mecha",
    "Music",
    "Mystery",
    "Psychological",
    "Romance",
    "Sci-Fi",
    "Slice of Life",
    "Sports",
    "Supernatural",
    "Thriller"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: pagePadding(context),
        child: SingleChildScrollView(
          child: Column(
            children: [
              topRow(context, "Genres"),
              ListView.builder(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: genres.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.only(left: 50, right: 50),
                    margin: EdgeInsets.only(top: 25),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => GenreItemPage(
                                  genreName: genres[index],
                                )));
                      },
                      child: Container(
                        height: 70,
                        width: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: AssetImage(
                              'lib/assets/images/mitsuha.jpg',
                            ),
                            fit: BoxFit.cover,
                            opacity: 0.35,
                          ),
                          border: Border.all(color: accentColor),
                        ),
                        child: Center(
                          child: Text(
                            genres[index],
                            style: TextStyle(
                              color: textMainColor,
                              fontFamily: "NotoSans",
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GenreItemPage extends StatefulWidget {
  final String genreName;
  const GenreItemPage({super.key, required this.genreName});

  @override
  State<GenreItemPage> createState() => _GenreItemPageState();
}

class _GenreItemPageState extends State<GenreItemPage> {
  @override
  void initState() {
    try {
      loadTrendingList();
      loadGenrePopularList();
    } catch (e) {
      if (currentUserSettings!.showErrors == true) floatingSnackBar(context, e.toString());
    }
    super.initState();
  }

  List<AnimeWidget> genreTrendingList = [];
  List<AnimeWidget> genrePopularList = [];
  bool trendingLoading = false;
  bool popularLoading = false;

  Future<void> loadTrendingList() async {
    trendingLoading = true;
    final res = await AnilistQueries().getGenreTrending(widget.genreName);
    List<AnimeWidget> cards = [];
    for (final item in res) {
      cards.add(AnimeWidget(
          widget: animeCard(item.title['english'] ?? item.title['romaji'] ?? "", item.cover), info: {'id': item.id}));
    }
    setState(() {
      genreTrendingList = cards;
      trendingLoading = false;
    });
  }

  Future<void> loadGenrePopularList() async {
    popularLoading = true;
    final res = await AnilistQueries().getGenrePopular(widget.genreName);
    List<AnimeWidget> cards = [];
    for (final item in res) {
      cards.add(AnimeWidget(
          widget: animeCard(item.title['english'] ?? item.title['romaji'] ?? "", item.cover), info: {'id': item.id}));
    }
    setState(() {
      genrePopularList = cards;
      popularLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        padding: pagePadding(context),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: topRow(
                context,
                widget.genreName,
              ),
            ),
            _title("Trending ${widget.genreName}"),
            _list(genreTrendingList, trendingLoading),
            _title("Popular ${widget.genreName}"),
            _list(genrePopularList, popularLoading),
          ],
        ),
      ),
    );
  }

  Container _title(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: textMainColor,
              fontFamily: "Rubik",
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Container _list(List<AnimeWidget> list, bool loading) {
    return Container(
      height: 250,
      padding: EdgeInsets.only(left: 5, right: 5),
      child: loading
          ? Center(
              child: CircularProgressIndicator(
                color: accentColor,
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: list.length,
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  child: list[index].widget,
                );
              },
            ),
    );
  }
}
