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
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1 / 0.4,
            // mainAxisSpacing: 1,
            // crossAxisSpacing: 1,
          ),
          itemCount: genres.length,
          itemBuilder: (context, index) {
            return  Container(
               padding: EdgeInsets.only(left: 20, right: 20),
              margin: EdgeInsets.only(top: 30),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                // onTap: () {
                //   Navigator.of(context).push(
                //       MaterialPageRoute(builder: (context) => GenresPage()));
                // },
                child: Container(
                  height: 50,
                  width: 150,
                 
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                        image: AssetImage(
                          'lib/assets/images/mitsuha.jpg',
                        ),
                        fit: BoxFit.cover,
                        opacity: 0.35),
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
      ),
    );
  }
}
