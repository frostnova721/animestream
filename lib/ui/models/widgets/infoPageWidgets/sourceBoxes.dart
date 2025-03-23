import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/models/bottomSheets/manualSearchSheet.dart';
import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/models/sources.dart';
import 'package:flutter/material.dart';

class SourceSideWidget extends StatelessWidget {
  final InfoProvider provider;
  const SourceSideWidget({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    String sourceMatchString = "Searching... ";
    IconData statusIcon;
    Color statusColor;

    if (provider.foundName != null) {
      bool isMatched = (provider.foundName == provider.data.title['english']) ||
          (provider.foundName == provider.data.title['romaji']);

      sourceMatchString = "Matching title ${isMatched ? "found" : "not found"}";
      statusIcon = isMatched ? Icons.check_circle_rounded : Icons.error_rounded;
      statusColor = isMatched ? Colors.green.shade400 : Colors.orange.shade400;
    } else {
      statusIcon = Icons.search_rounded;
      statusColor = appTheme.textMainColor.withAlpha(153);
    }

    final size = MediaQuery.of(context).size;

    return Container(
      margin: EdgeInsets.only(
        left: 60,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: appTheme.backgroundSubColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 15,
            offset: Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            appTheme.backgroundSubColor,
            appTheme.backgroundSubColor.withAlpha(230),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 10, left: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.playlist_play_rounded,
                                size: 18,
                                color: appTheme.accentColor.withAlpha(178),
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Select Source",
                                style: TextStyle(
                                  color: appTheme.textMainColor.withAlpha(220),
                                  fontFamily: "Rubik",
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: appTheme.textMainColor.withAlpha(60),
                              width: 1,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                appTheme.backgroundSubColor.withAlpha(127),
                                appTheme.backgroundSubColor,
                              ],
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: ButtonTheme(
                              alignedDropdown: true,
                              child: DropdownButton<String>(
                                isExpanded: true,
                                menuMaxHeight: 300,
                                icon: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: appTheme.accentColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: appTheme.accentColor,
                                    size: 20,
                                  ),
                                ),
                                value: provider.selectedSource,
                                onChanged: (val) {
                                  if (val != null) {
                                    provider.selectedSource = val;
                                    provider.getEpisodes();
                                  }
                                },
                                dropdownColor: appTheme.backgroundSubColor.withAlpha(242),
                                borderRadius: BorderRadius.circular(14),
                                style: TextStyle(
                                  color: appTheme.textMainColor,
                                  fontFamily: "Poppins",
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                items: sources
                                    .map((source) => DropdownMenuItem(
                                          value: source,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: appTheme.accentColor.withAlpha(153),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Text(source),
                                              ],
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: appTheme.textMainColor.withAlpha(10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: provider.foundName == null
                            ? appTheme.textMainColor.withAlpha(30)
                            : (provider.foundName == provider.data.title['english'] ||
                                    provider.foundName == provider.data.title['romaji'])
                                ? Colors.green.withAlpha(50)
                                : Colors.orange.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                statusIcon,
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Source Status",
                                    style: TextStyle(
                                      color: appTheme.textMainColor.withAlpha(150),
                                      fontFamily: "Poppins",
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    sourceMatchString,
                                    style: TextStyle(
                                      color: appTheme.textMainColor.withAlpha(230),
                                      fontFamily: "Poppins",
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final title = provider.data.title['english'] ?? provider.data.title['romaji'] ?? "no bs";
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    backgroundColor: appTheme.backgroundColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.all(24),
                                      width: size.width / 3,
                                      height: size.height / 2,
                                      child: ManualSearchSheet(
                                        searchString: title,
                                        source: provider.selectedSource,
                                        anilistId: provider.id.toString(),
                                      ),
                                    ),
                                  );
                                },
                              ).then((result) async {
                                if (result == null) return;
                                provider.epSearcherror = false;
                                provider.foundName = null;
                                final links = await getAnimeEpisodes(provider.selectedSource, result['alias']);

                                provider.paginate(links);
                                provider.foundName = result['name'];
                              });
                            },
                            icon: Icon(
                              Icons.search_rounded,
                              size: 18,
                            ),
                            label: Text(
                              "Manual Search",
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              // backgroundColor: appTheme.backgroundColor,
                              elevation: 2,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        if (provider.foundName == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 14,
                                  color: appTheme.textMainColor.withAlpha(130),
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    "Use manual search if automatic matching fails",
                                    style: TextStyle(
                                      color: appTheme.textMainColor.withAlpha(130),
                                      fontFamily: "Poppins",
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SourceBodyWidget extends StatelessWidget {
  final InfoProvider provider;
  const SourceBodyWidget({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable cus it is used!
    String sourceMatchString = "Searching... ";
    IconData statusIcon;
    Color statusColor;

    if (provider.foundName != null) {
      bool isMatched = (provider.foundName == provider.data.title['english']) ||
          (provider.foundName == provider.data.title['romaji']);

      sourceMatchString = "Matching title ${isMatched ? "found" : "not found"}";
      statusIcon = isMatched ? Icons.check_circle_rounded : Icons.error_rounded;
      statusColor = isMatched ? Colors.green.shade400 : Colors.orange.shade400;
    } else {
      statusIcon = Icons.search_rounded;
      statusColor = appTheme.textMainColor.withAlpha(153);
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: appTheme.backgroundSubColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 15,
              offset: Offset(0, 5),
              spreadRadius: 1,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              appTheme.backgroundSubColor,
              appTheme.backgroundSubColor.withAlpha(204),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    appTheme.accentColor.withAlpha(50),
                    appTheme.accentColor.withAlpha(15),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "Source Selection",
                        style: TextStyle(
                          color: appTheme.textMainColor,
                          fontFamily: "Poppins",
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appTheme.accentColor.withAlpha(70),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.playlist_play_rounded,
                      color: appTheme.accentColor,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Select Source",
                              style: TextStyle(
                                color: appTheme.textMainColor.withAlpha(204),
                                fontFamily: "Poppins",
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(51),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    provider.foundName != null
                                        ? (provider.foundName == provider.data.title['english'] ||
                                                provider.foundName == provider.data.title['romaji']
                                            ? "Matched"
                                            : "Not Matched")
                                        : "Searching",
                                    style: TextStyle(
                                      color: statusColor,
                                      fontFamily: "Poppins",
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: appTheme.textMainColor.withAlpha(60),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              menuMaxHeight: 300,
                              icon: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: appTheme.accentColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: appTheme.accentColor,
                                  size: 20,
                                ),
                              ),
                              value: provider.selectedSource,
                              onChanged: (val) {
                                if (val != null) {
                                  provider.selectedSource = val;
                                  provider.getEpisodes();
                                }
                              },
                              dropdownColor: appTheme.backgroundSubColor.withAlpha(242),
                              borderRadius: BorderRadius.circular(14),
                              style: TextStyle(
                                color: appTheme.textMainColor,
                                fontFamily: "Poppins",
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              items: sources
                                  .map((source) => DropdownMenuItem(
                                        value: source,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: appTheme.accentColor.withAlpha(153),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Text(source),
                                            ],
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final title = provider.data.title['english'] ?? provider.data.title['romaji'] ?? "no bs";
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              backgroundColor: appTheme.backgroundColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                padding: EdgeInsets.all(24),
                                width: MediaQuery.of(context).size.width / 3,
                                height: MediaQuery.of(context).size.height / 2,
                                child: ManualSearchSheet(
                                  searchString: title,
                                  source: provider.selectedSource,
                                  anilistId: provider.id.toString(),
                                ),
                              ),
                            );
                          },
                        ).then((result) async {
                          if (result == null) return;
                          provider.epSearcherror = false;
                          provider.foundName = null;
                          final links = await getAnimeEpisodes(provider.selectedSource, result['alias']);

                          provider.paginate(links);
                          provider.foundName = result['name'];
                        });
                      },
                      icon: Icon(
                        Icons.search_rounded,
                        size: 18,
                      ),
                      label: Text(
                        "Manual Search",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 2,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  // Usage hint text
                  if (provider.foundName == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: appTheme.textMainColor.withAlpha(130),
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "Use manual search if automatic matching fails",
                              style: TextStyle(
                                color: appTheme.textMainColor.withAlpha(130),
                                fontFamily: "Poppins",
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
