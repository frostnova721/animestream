import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class AnimeWidget {
  Widget widget;
  Map<String, dynamic> info;

  AnimeWidget({required this.widget, required this.info});
}

Widget characterCard(String name, String role, String imageUrl) {
  return Card(
    color: backgroundColor,
    clipBehavior: Clip.hardEdge,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.hardEdge,
          height: 175,
          width: 115,
          child: Image.network(
            fit: BoxFit.cover,
            imageUrl,
            height: 175,
            width: 115,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 5, left: 5, right: 5),
          child: Text(
            name,
            style: TextStyle(
              color: textMainColor,
              fontFamily: 'NotoSans',
              fontSize: 15,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
        ),
        Text(
          role,
          style: TextStyle(
            color: textSubColor,
            fontFamily: 'NotoSans',
            fontSize: 12,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

Widget NewsCard(String title, String imageUrl, String date, String time) {
  return Card(
    surfaceTintColor: textSubColor,
    color: backgroundColor,
    child: Container(
      decoration: BoxDecoration(
          // boxShadow: [BoxShadow(color: Color.fromARGB(82, 92, 92, 92), blurRadius: 10, blurStyle: BlurStyle.normal, offset: Offset(0.0, 3), spreadRadius: 0)],
          color: Colors.transparent),
      height: 200,
      padding: EdgeInsets.only(right: 10),
      child: Row(
        children: [
          Container(
            margin: EdgeInsets.only(right: 20),
            width: 135,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                  image: NetworkImage(
                    imageUrl,
                  ),
                  fit: BoxFit.cover),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 5,
                    style: TextStyle(
                      color: textMainColor,
                      fontSize: 18,
                      fontFamily: "Rubik",
                    ),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    "$date • $time",
                    style: TextStyle(
                      fontFamily: "NotoSans",
                      fontSize: 13,
                      color: textSubColor,
                    ),
                  ),
                ),
                // ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget animeCard(String title, String imageUrl, { bool ongoing= false }) {
  return Card(
    color: backgroundColor,
    shadowColor: null,
    borderOnForeground: false,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(
                  imageUrl,
                ),
                fit: BoxFit.cover
              )),
          // clipBehavior: Clip.hardEdge,
          height: 165,
          width: 110,
          child: ongoing ? Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: Colors.green,spreadRadius: 2)
                  ],
                  borderRadius: BorderRadius.circular(100),
                  color: Color.fromARGB(255, 46, 236, 52),
                  border: Border.all(color: Colors.black, width: 2)
                ),
              ),
            ],
          ) : Container(),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 5),
          child: Text(
            title,
            style: TextStyle(
              color: textMainColor,
              fontFamily: 'NotoSans',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 2,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    ),
  );
}

class AnimeData {
  final String imageUrl;
  final String title;

  const AnimeData({
    required this.imageUrl,
    required this.title,
  });
}
