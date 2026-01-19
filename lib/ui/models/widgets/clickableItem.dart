import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/ui/pages/settingPages/common.dart';
import 'package:flutter/material.dart';

// Represents the button tiles which are clickable in setting screen
class ClickableItem extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final String? description;
  final Icon? suffixIcon;
  final EdgeInsets? contentPadding;
  final BorderRadius? borderRadius;
  const ClickableItem({
    super.key,
    required this.onTap,
    required this.label,
    this.description,
    this.suffixIcon,
    this.borderRadius,
    this.contentPadding = const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Container(
        padding: contentPadding,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
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
            if (suffixIcon != null) suffixIcon!,
          ],
        ),
      ),
    );
  }
}
