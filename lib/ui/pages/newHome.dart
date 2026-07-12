import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/providers/mainNavProvider.dart';
import 'package:animestream/ui/pages/settings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewHome extends StatefulWidget {
  final MainNavProvider mainNavProvider;
  const NewHome({super.key, required this.mainNavProvider});

  @override
  State<NewHome> createState() => _NewHomeState();
}

class _NewHomeState extends State<NewHome> {
  @override
  void initState() {
    super.initState();

    widget.mainNavProvider.init();

    _carouselController.addListener(_listener);
  }

  void _listener() {
    if (_carouselController.position.hasPixels) {
      // Calculate current index based on pixels and item width
      final int index = (_carouselController.position.pixels / _carouselItemWidth).round();
      if (_currentIndex != index) {
        setState(() {
          _currentIndex = index;
        });
      }
    }
  }

  final CarouselController _carouselController = CarouselController(initialItem: 0);
  int _currentIndex = 0;
  final double _carouselItemWidth = 325;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MainNavProvider>();
    return Scaffold(
        body: Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 5, right: 5),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.mainNavProvider.userProfile?.name ?? "no usah",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => SettingsPage()));
                    },
                    icon: Icon(
                      Icons.settings_rounded,
                      size: 36,
                    )),
              ],
            ),
            _title("Continue Watching"),
            SizedBox(
              height: 200,
              child: CarouselView(
                controller: _carouselController,
                itemExtent: _carouselItemWidth,
                scrollDirection: Axis.horizontal,
                itemSnapping: true,
                children: List.generate(provider.recentlyWatched.items.length, (idx) {
                  final it = provider.recentlyWatched.items[idx];
                  final title = it.title['english'] ?? it.title['romaji'] ?? "";
                  return Container(
                      width: 300,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: CachedNetworkImageProvider(it.coverImage), opacity: 0.6, fit: BoxFit.cover),
                      ),
                      child: idx != _currentIndex
                          ? null
                          : Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      stops: [0.1, 1],
                                      colors: [appTheme.backgroundColor, appTheme.backgroundColor.withAlpha(0)])),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox.shrink(),
                                  Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (currentUserSettings?.nativeTitle ?? false)
                                              ? it.title['native'] ?? title
                                              : title,
                                          style: TextStyle(
                                              fontFamily: "Rubik", fontSize: 22, overflow: TextOverflow.ellipsis),
                                          maxLines: 2,
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              height: 30,
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                  color: appTheme.accentColor, borderRadius: BorderRadius.circular(10)),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.star_rounded, size: 18, color: appTheme.onAccent),
                                                  Text(" ${it.rating?.toString() ?? "??"}",
                                                      style: TextStyle(
                                                          color: appTheme.onAccent,
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              margin: EdgeInsets.only(left: 12),
                                              height: 30,
                                              decoration: BoxDecoration(
                                                  color: appTheme.accentColor, borderRadius: BorderRadius.circular(10)),
                                              child: Text(
                                                "${it.watchedEpisodeCount ?? "~"} | ${it.totalEpisodes ?? "??"}",
                                                style: TextStyle(
                                                    fontSize: 18, fontFamily: "Rubik", color: appTheme.onAccent),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ));
                }).toList(),
              ),
            ),
            _title("Trending"),
            SizedBox(
              height: 300,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    mainAxisExtent: MediaQuery.of(context).size.width / 1.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10),
                itemCount: provider.thisSeasonData.length,
                itemBuilder: (context, index) {
                  final it = provider.thisSeasonData[index];
                  final title = it.title['english'] ?? it.title['romaji'] ?? "";
                  return Container(
                    width: (MediaQuery.of(context).size.width / 2) - 10,
                    padding: EdgeInsets.all(12),
                    alignment: Alignment.bottomLeft,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(it.cover),
                          fit: BoxFit.cover,
                          opacity: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(15)),
                    child: Text(
                      currentUserSettings?.nativeTitle ?? false ? it.title['native'] ?? "" : title,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                      maxLines: 2,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _title(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 20, bottom: 5),
      child: Text(text, style: TextStyle(fontFamily: "Rubik", fontWeight: FontWeight.bold, fontSize: 24)),
    );
  }
}
