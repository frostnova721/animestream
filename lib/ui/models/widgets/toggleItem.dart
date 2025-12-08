import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';

class ToggleItem extends StatelessWidget {
  final VoidCallback onTapFunction;
  final String label;
  final String? description;
  final bool value;

  const ToggleItem({
    super.key,
    required this.onTapFunction,
    required this.label,
    this.description,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapFunction,
      child: Container(
        padding: EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
        child: Container(
          padding: EdgeInsets.only(
            left: 10,
            right: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textStyle(),
                    ),
                    if (description != null)
                      Text(
                        description!,
                        style: textStyle().copyWith(color: appTheme.textSubColor, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: (val) {
                  onTapFunction();
                },
                inactiveTrackColor: appTheme.backgroundColor,
                activeColor: appTheme.backgroundColor,
                activeTrackColor: appTheme.accentColor,
              )
            ],
          ),
        ),
      ),
    );
  }
}
