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

  TextEditingController textEditingController = TextEditingController();

  bool _searching = false;

  Future addCards(String query) async {
    results = [];
    final searchResults = await Anilist().search(query);
    searchResults.forEach((ele) {
      final image =
          ele['coverImage']['large'] ?? ele['coverImage']['extraLarge'];
      final title = ele['title']['english'] ?? ele['title']['romaji'];
      // final id = ele['id'];
      results.add(ListElement(widget: animeCard(title, image), info: ele));
      setState(() {
        _searching = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          SizedBox(
            height: 60,
          ),
          Container(
            padding: EdgeInsets.only(left: 25, right: 25, top: 25),
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
                  : _searchResults()),
        ],
      ),
    );
  }

  Container _searchResults() {
    return Container(
      foregroundDecoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black,
            Colors.transparent,
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: [0, 0.05],
        ),
      ),
      padding: EdgeInsets.only(left: 15, right: 15),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisSpacing: 15,
          crossAxisCount: 3,
          crossAxisSpacing: 3,
          childAspectRatio: 1 / 2.055,
        ),
        shrinkWrap: false,
        itemCount: results.length,
        itemBuilder: (context, index) {
          return Container(
            child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Info(id: results[index].info['id']),
                    ),
                  );
                },
                child: results[index].widget),
          );
        },
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
}
