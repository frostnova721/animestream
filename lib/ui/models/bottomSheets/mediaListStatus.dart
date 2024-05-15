import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/database/anilist/mutations.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

class MediaListStatusBottomSheet extends StatefulWidget {
  final MediaStatus? status;
  final int id;
  final Function(String, int) refreshListStatus;
  final int totalEpisodes;
  final int episodesWatched;

  const MediaListStatusBottomSheet({
    super.key,
    required this.status,
    required this.id,
    required this.refreshListStatus,
    required this.totalEpisodes,
    required this.episodesWatched,
  });

  @override
  State<MediaListStatusBottomSheet> createState() =>
      _MediaListStatusBottomSheetState();
}

class _MediaListStatusBottomSheetState
    extends State<MediaListStatusBottomSheet> {
  @override
  void initState() {
    super.initState();
    itemList = makeItemList();
    textEditingController.value =
        TextEditingValue(text: "${widget.episodesWatched}");
  }

  final List<String> statuses = ["PLANNING", "CURRENT", "DROPPED", "COMPLETED"];

  List<DropdownMenuEntry> itemList = [];
  String? initialSelection;

  List<DropdownMenuEntry> makeItemList() {
    final List<DropdownMenuEntry> itemList = [];
    statuses.forEach((element) {
      itemList.add(
        DropdownMenuEntry(
          value: element,
          label: element,
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            textStyle: WidgetStatePropertyAll(
              TextStyle(
                color: Colors.white,
                fontFamily: "Rubik",
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    });
    return itemList;
  }

  String getInitialSelection() {
    if (widget.status == null) {
      initialSelection = itemList[0].value;
      return itemList[0].value;
    } else {
      initialSelection = widget.status!.name;
      selectedValue = initialSelection;
      return widget.status!.name;
    }
  }

  String? selectedValue;

  TextEditingController textEditingController = TextEditingController();
  TextEditingController menuController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                DropdownMenu(
                  controller: menuController,
                  onSelected: (value) => {
                    if (value != initialSelection) selectedValue = value,
                  },
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(backgroundColor),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          width: 1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontFamily: "Poppins",
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(width: 1, color: Colors.white),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          width: 1,
                                          color: Colors.white,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                    contentPadding: EdgeInsets.only(left: 20, right: 20),
                  ),
                  width: 300,
                  label: Text(
                    "status",
                    style: TextStyle(color: textMainColor, fontFamily: "Poppins"),
                  ),
                  initialSelection: getInitialSelection(),
                  dropdownMenuEntries: itemList,
                ),
                Container(
                  padding: EdgeInsets.only(top: 20, bottom: 20),
                  child: Text(
                    "Progress",
                    style: TextStyle(
                      color: textMainColor,
                      fontFamily: "Rubik",
                      fontSize: 22,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        final currentNumber = int.parse(
                            textEditingController.value.text.isEmpty
                                ? "0"
                                : textEditingController.value.text);
                        if (currentNumber < 1) return;
                        textEditingController.value =
                            TextEditingValue(text: "${currentNumber - 1}");
                      },
                      icon: Icon(
                        Icons.remove_circle_outline_rounded,
                        color: textMainColor,
                        size: 35,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.only(right: 10),
                          height: 50,
                          width: 100,
                          child: TextField(
                            controller: textEditingController,
                            onChanged: (value) => {
                              if (value.isNotEmpty &&
                                  int.parse(value) > widget.totalEpisodes)
                                {
                                  textEditingController.value = TextEditingValue(
                                    text: "${widget.totalEpisodes}",
                                  ),
                                }
                            },
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.only(
                                  top: 5, bottom: 5, left: 10, right: 10),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: textMainColor,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              color: textMainColor,
                              fontFamily: "Rubik",
                              fontSize: 20,
                            ),
                            autocorrect: false,
                          ),
                        ),
                        Text(
                          "/ ${widget.totalEpisodes}",
                          style: TextStyle(
                            color: textMainColor,
                            fontFamily: "Rubik",
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        final currentNumber = int.parse(
                            textEditingController.value.text.isEmpty
                                ? "0"
                                : textEditingController.value.text);
                        if (currentNumber + 1 >= widget.totalEpisodes) {
                          menuController.value =
                              TextEditingValue(text: "COMPLETED");
                          selectedValue = "COMPLETED";
                        }
                        if (currentNumber + 1 > widget.totalEpisodes) return;
                        textEditingController.value =
                            TextEditingValue(text: "${currentNumber + 1}");
                      },
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        color: textMainColor,
                        size: 35,
                      ),
                    )
                  ],
                )
              ],
            ),
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom+5, top: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        // padding: EdgeInsets.zero,
                        backgroundColor: accentColor,
                        side: BorderSide(
                          color: accentColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 0),
                        child: Text(
                          "cancel",
                          style: TextStyle(
                            color: backgroundColor,
                            fontFamily: "Poppins",
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      side: BorderSide(
                        color: accentColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      final int progress =
                          int.parse(textEditingController.value.text);
                      if (selectedValue != null ||
                          progress != widget.episodesWatched || widget.status == null) {
                        AnilistMutations()
                            .mutateAnimeList(
                          id: widget.id,
                          status: assignItemEnum(selectedValue ?? initialSelection!),
                          progress: progress,
                        )
                            .then((value) {
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                          floatingSnackBar(context, "The list has been updated!");
                        });
                        initialSelection = selectedValue;
                        widget.refreshListStatus(selectedValue ?? initialSelection!, progress);
                      }
                    },
                    child: Text(
                      "save",
                      style: TextStyle(
                        color: backgroundColor,
                        fontFamily: "Poppins",
                        fontSize: 22,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    textEditingController.dispose();
    menuController.dispose();
    super.dispose();
  }
}
