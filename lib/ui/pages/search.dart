import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'info.dart';

class Search extends StatefulWidget {
  final String searchedText;
  const Search({super.key, required this.searchedText});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  List<ListElement> results = [];
  List<ListElement> exactMatches = [];

  TextEditingController textEditingController = TextEditingController();

  bool _searching = false;

  Future addCards(String query) async {
    results = [];
    final searchResults = await Anilist().search(query);
    searchResults.forEach((ele) {
      final image =
          ele['coverImage']['large'] ?? ele['coverImage']['extraLarge'];
      final String title = ele['title']['english'] ?? ele['title']['romaji'];
      // final id = ele['id'];
      results.add(ListElement(widget: animeCard(title, image), info: ele));
      if (query.toLowerCase() == title.toLowerCase()) {
        exactMatches
            .add(ListElement(widget: animeCard(title, image), info: ele));
      }
    });
    setState(() {
      _searching = false;
    });
  }

  @override
  void initState() {
    super.initState();
    textEditingController.value = TextEditingValue(text: widget.searchedText);
    setState(() {
      _searching = true;
    });
    addCards(widget.searchedText);
  }

  bool exactMatch = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Column(
          children: [
            Container(
              padding:
                  EdgeInsets.only(top: 15, left: 25, right: 25, bottom: 25),
              child: _searchBar(),
            ),
            Expanded(
              child: _searching
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SpinKitThreeBounce(
                          color: accentColor,
                          size: 35,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            "searching...",
                            style: TextStyle(
                                color: accentColor,
                                fontFamily: "NotoSans",
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        )
                      ],
                    )
                  : _searchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Container _searchResults() {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 15),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Checkbox(
                    value: exactMatch,
                    onChanged: (val) => setState(() {
                      exactMatch = val!;
                    }),
                    activeColor: accentColor,
                    checkColor: Colors.black,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(
                    "exact match",
                    style: TextStyle(
                      color: textMainColor,
                      fontFamily: "NotoSans",
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
            OrientationBuilder(
              builder: (context, orientation) {
                return GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          orientation == Orientation.portrait ? 3 : 7,
                      // childAspectRatio: 1 / 1.88,
                      childAspectRatio: 120 /
                          225 //set as width and height of each child container
                      ),
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: exactMatch ? exactMatches.length : results.length,
                  itemBuilder: (context, index) {
                    return Container(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Info(
                                id: exactMatch
                                    ? exactMatches[index].info['id']
                                    : results[index].info['id'],
                              ),
                            ),
                          );
                        },
                        child: exactMatch
                            ? exactMatches[index].widget
                            : results[index].widget,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  TextField _searchBar() {
    return TextField(
      controller: textEditingController,
      onSubmitted: (val) async {
        setState(() {
          _searching = true;
        });
        await addCards(val);
      },
      autocorrect: false,
      cursorColor: accentColor,
      decoration: InputDecoration(
        suffixIcon: Padding(
          padding: EdgeInsets.only(right: 10),
          child: Image.asset(
            'lib/assets/images/search.png',
            color: Colors.white,
            scale: 1.75,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: BorderSide(width: 1.5, color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: BorderSide(color: accentColor),
        ),
        hintText: "Search...",
        hintStyle: TextStyle(
            fontFamily: "Poppins", color: Color.fromARGB(255, 168, 168, 168)),
        contentPadding:
            EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 15),
      ),
      style: TextStyle(color: Colors.white, fontFamily: "Poppins"),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
