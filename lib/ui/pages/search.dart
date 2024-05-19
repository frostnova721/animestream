import 'dart:async';

import 'package:animestream/core/database/anilist/anilist.dart';
import 'package:animestream/ui/models/cards.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class Search extends StatefulWidget {
  final String searchedText;
  const Search({super.key, required this.searchedText});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  List<Card> results = [];
  List<Card> exactMatches = [];

  TextEditingController textEditingController = TextEditingController();

  bool _searching = false;

  Timer? debounce;

  Future addCards(String query) async {
    results = [];
    exactMatches = [];
    final searchResults = await Anilist().search(query);
    searchResults.forEach((ele) {
      final image = ele.cover;
      final String title = ele.title['english'] ?? ele.title['romaji'] ?? '';
      final id = ele.id;
      results.add(
          Cards(context: context).animeCard(id, title, image), 
        );
      if (query.toLowerCase() == title.toLowerCase()) {
        exactMatches.add(
         Cards(context: context).animeCard(id, title, image),
           );
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
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: MediaQuery.of(context).padding.left),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: 15, left: 25, right: 25, bottom: 25),
              child: _searchBar(),
            ),
            Expanded(
              child: _searching
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: accentColor,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            "searching...",
                            style: TextStyle(
                                color: accentColor, fontFamily: "NotoSans", fontWeight: FontWeight.bold, fontSize: 16),
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
            GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).orientation == Orientation.portrait ? 3 : 6,
                  // childAspectRatio: 1 / 1.88,
                  childAspectRatio: 120 / 225, //set as width and height of each child container
                  mainAxisSpacing: 15),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: exactMatch ? exactMatches.length : results.length,
              itemBuilder: (context, index) {
                return Container(
                  child: exactMatch ? exactMatches[index] : results[index],
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
      onChanged: (val) {
        if (debounce?.isActive ?? false) debounce?.cancel();
        debounce = Timer(const Duration(milliseconds: 300), () async {
          if (val.length <= 0) {
            return;
          }
          setState(() {
            _searching = true;
          });
          await addCards(val);
        });
      },
      onSubmitted: (val) async {
        if (val.length <= 0) {
          return;
        }
        setState(() {
          _searching = true;
        });
        await addCards(val);
      },
      autocorrect: false,
      cursorColor: accentColor,
      decoration: InputDecoration(
        labelText: "search",
        labelStyle: TextStyle(color: textMainColor, fontFamily: "Rubik", fontWeight: FontWeight.bold, fontSize: 17),
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
        hintStyle: TextStyle(fontFamily: "Poppins", color: Color.fromARGB(255, 168, 168, 168)),
        contentPadding: EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 15),
      ),
      style: TextStyle(color: Colors.white, fontFamily: "Poppins"),
    );
  }

  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }
}
