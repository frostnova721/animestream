import 'dart:math';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/utils.dart';
import 'package:animestream/core/database/handler/syncHandler.dart';
import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:flutter/material.dart';

class MediaListStatusBottomSheet extends StatefulWidget {
  final InfoProvider provider;

  const MediaListStatusBottomSheet({
    super.key,
    required this.provider,
  });

  @override
  State<MediaListStatusBottomSheet> createState() => _MediaListStatusBottomSheetState();
}

class _MediaListStatusBottomSheetState extends State<MediaListStatusBottomSheet> {
  @override
  void initState() {
    super.initState();
    itemList = makeItemList();
    textEditingController.value = TextEditingValue(text: "${widget.provider.watched}");
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
            foregroundColor: WidgetStatePropertyAll(appTheme.textMainColor),
            textStyle: WidgetStatePropertyAll(
              TextStyle(
                color: appTheme.textMainColor,
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
    if (widget.provider.mediaListStatus == null) {
      initialSelection = itemList[0].value;
      print("set initial to $initialSelection");
      return itemList[0].value;
    } else {
      initialSelection = widget.provider.mediaListStatus!.name;
      selectedValue = initialSelection;
      return widget.provider.mediaListStatus!.name;
    }
  }

  String? selectedValue;

  TextEditingController textEditingController = TextEditingController();
  TextEditingController menuController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final isDialog = MediaQuery.of(context).size.width > 800;

    // Thanks Claude for the design!!!
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: isDialog ? 16 : 24,
      ),
      decoration: BoxDecoration(
        color: appTheme.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isDialog ? 16 : 24),
          topRight: Radius.circular(isDialog ? 16 : 24),
          bottomLeft: Radius.circular(isDialog ? 16 : 0),
          bottomRight: Radius.circular(isDialog ? 16 : 0),
        ),
        boxShadow: isDialog
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 20,
                  offset: Offset(0, 5),
                )
              ]
            : null,
      ),
      width: isDialog ? min(500, MediaQuery.of(context).size.width * 0.85) : double.infinity,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: EdgeInsets.only(bottom: 20, top: isDialog ? 8 : 0),
              child: Text(
                "Update Progress",
                style: TextStyle(
                  color: appTheme.textMainColor,
                  fontFamily: "Rubik",
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Status Dropdown
            Text(
              "Status",
              style: TextStyle(
                color: appTheme.textMainColor.withAlpha(204),
                fontFamily: "Poppins",
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownMenu(
                controller: menuController,
                onSelected: (value) {
                  if (value != initialSelection) selectedValue = value;
                },
                enableSearch: false,
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(appTheme.backgroundColor),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        width: 1,
                        color: appTheme.textMainColor.withAlpha(51),
                      ),
                    ),
                  ),
                  elevation: WidgetStatePropertyAll(8),
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
                ),
                textStyle: TextStyle(
                  color: appTheme.textMainColor,
                  fontFamily: "Poppins",
                  fontSize: 16,
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: appTheme.backgroundColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 1, color: appTheme.textMainColor.withAlpha(51)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1,
                      color: appTheme.textMainColor.withAlpha(51),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1.5,
                      color: appTheme.accentColor,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                width: 350,
                initialSelection: getInitialSelection(),
                dropdownMenuEntries: itemList,
              ),
            ),

            // Progress Section
            const SizedBox(height: 24),
            Text(
              "Progress",
              style: TextStyle(
                color: appTheme.textMainColor.withAlpha(204),
                fontFamily: "Poppins",
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: appTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: appTheme.textMainColor.withAlpha(25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ProgressButton(
                    icon: Icons.remove_rounded,
                    onPressed: () {
                      final currentNumber =
                          int.parse(textEditingController.value.text.isEmpty ? "0" : textEditingController.value.text);
                      if (currentNumber < 1) return;
                      textEditingController.value = TextEditingValue(text: "${currentNumber - 1}");
                    },
                    color: appTheme.textMainColor,
                    backgroundColor: appTheme.textMainColor.withAlpha(25),
                  ),
                  Row(
                    children: [
                      Container(
                        height: 48,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: appTheme.backgroundColor,
                          border: Border.all(
                            color: appTheme.textMainColor.withAlpha(51),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: textEditingController,
                          onChanged: (value) {
                            if (value.isNotEmpty && int.parse(value) > (provider.data.episodes ?? 9999)) {
                              textEditingController.value = TextEditingValue(
                                text: "${provider.data.episodes ?? 0}",
                              );
                            }
                          },
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          style: TextStyle(
                            color: appTheme.textMainColor,
                            fontFamily: "Rubik",
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                          autocorrect: false,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "of ${provider.data.episodes ?? 0}",
                          style: TextStyle(
                            color: appTheme.textMainColor.withAlpha(178),
                            fontFamily: "Rubik",
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _ProgressButton(
                    icon: Icons.add_rounded,
                    onPressed: () {
                      final currentNumber =
                          int.parse(textEditingController.value.text.isEmpty ? "0" : textEditingController.value.text);
                      if (currentNumber + 1 >= (provider.data.episodes ?? 0)) {
                        menuController.value = TextEditingValue(text: "COMPLETED");
                        selectedValue = "COMPLETED";
                      }
                      if (currentNumber + 1 > (provider.data.episodes ?? 0)) return;
                      textEditingController.value = TextEditingValue(text: "${currentNumber + 1}");
                    },
                    color: appTheme.textMainColor,
                    backgroundColor: appTheme.textMainColor.withAlpha(25),
                  )
                ],
              ),
            ),

            // Buttons
            Padding(
              padding: EdgeInsets.only(top: 32, bottom: isDialog ? 8 : MediaQuery.of(context).padding.bottom + 16),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: "Cancel",
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      backgroundColor: appTheme.textMainColor.withAlpha(25),
                      textColor: appTheme.textMainColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionButton(
                      label: "Save",
                      onPressed: () {
                        final int progress = int.parse(textEditingController.value.text);
                        if (selectedValue != null || progress != provider.watched || provider.mediaListStatus == null) {
                          SyncHandler()
                              .mutateAnimeList(
                                  id: provider.id,
                                  status: assignItemEnum(selectedValue ?? initialSelection!),
                                  previousStatus: assignItemEnum(initialSelection),
                                  progress: progress,
                                  otherIds: provider.altDatabases)
                              .then((value) {
                            initialSelection = selectedValue ?? initialSelection;
                            provider.refreshListStatus(selectedValue ?? initialSelection!, progress);
                            floatingSnackBar("The list has been updated!");
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          });
                        }
                      },
                      backgroundColor: appTheme.accentColor,
                      textColor: appTheme.onAccent,
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

  @override
  void dispose() {
    textEditingController.dispose();
    menuController.dispose();
    super.dispose();
  }
}

// Helper class for + and - buttons
class _ProgressButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final Color backgroundColor;

  const _ProgressButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }
}

// Helper class for action buttons
class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: Colors.transparent,
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: "Poppins",
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
