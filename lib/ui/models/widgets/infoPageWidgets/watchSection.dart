import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/models/widgets/infoPageWidgets/commonInfo.dart';
import 'package:flutter/material.dart';

class WatchSection extends StatelessWidget {
  final InfoProvider provider;
  final Size size;
  final int splitWidth;
  const WatchSection({super.key, required this.provider, required this.size, required this.splitWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: size.width / 10, top: 30),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, // Align the row contents to the top
                children: [
                  Column(
                    children: [
                      CommonInfo(
                        provider: provider,
                      ),
                    ],
                  ),
                ],
              ),
              if (size.width < splitWidth)
                Container()
            ],
          ),
        ),
      ],
    );
  }
}