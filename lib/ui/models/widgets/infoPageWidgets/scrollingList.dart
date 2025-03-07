import 'dart:io';

import 'package:animestream/core/database/types.dart';
import 'package:animestream/ui/models/widgets/cards.dart';
import 'package:flutter/material.dart';

class ScrollingList {
  static SizedBox character(
      BuildContext context, int splitWidth, ScrollController controller, List<Map<String, dynamic>> list) {
    final size = MediaQuery.sizeOf(context);
    return SizedBox(
      width: size.width / (size.width > splitWidth ? 1.75 : 1.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                child: Text(
                  "Characters",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
              _scrollButtons(controller),
            ],
          ),
          Container(
            height: 250,
            width: size.width / (size.width > splitWidth ? 1.75 : 1.3),
            child: ListView.builder(
              itemCount: list.length,
              scrollDirection: Axis.horizontal,
              controller: controller,
              itemBuilder: (context, index) {
                final it = list[index];
                return Cards().characterCard(it['name'], it['role'], it['image']);
              },
            ),
          ),
        ],
      ),
    );
  }

  static SizedBox animeCards(
      BuildContext context, int splitWidth, ScrollController controller, String title, List<DatabaseRelatedRecommendation> list) {
    final size = MediaQuery.sizeOf(context);
    return SizedBox(
      width: size.width / (size.width > splitWidth ? 1.75 : 1.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 20),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                _scrollButtons(controller),
              ],
            ),
          ),
          Container(
            height: 260,
            // width: size.width / (size.width > 1800 ? 1.75 : 1.3),
            child: ListView.builder(
              controller: controller,
              itemCount: list.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final it = list[index];
                return Cards(context: context).animeCard(it.id, it.title['english'] ?? it.title['romaji']!, it.cover,
                    isMobile: !Platform.isWindows, rating: it.rating, subText: it.relationType);
              },
            ),
          ),
        ],
      ),
    );
  }

  static Row _scrollButtons(ScrollController controller) {
    final scrollOffset = 500;
    return Row(
      spacing: 15,
      children: [
        OutlinedButton(
            onPressed: () {
              controller.animateTo(controller.offset - scrollOffset,
                  duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
            },
            child: Icon(Icons.arrow_back_ios_new_rounded)),
        OutlinedButton(
            onPressed: () {
              controller.animateTo(controller.offset + scrollOffset,
                  duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
            },
            child: Icon(Icons.arrow_forward_ios_rounded)),
      ],
    );
  }
}
