import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/types.dart';
import 'package:flutter/material.dart';

class SourceTile extends StatefulWidget {
  final VideoStream source;
  final VoidCallback onTap;
  const SourceTile({
    super.key,
    required this.source,
    required this.onTap,
  });

  @override
  State<SourceTile> createState() => _SourceTileState();
}

class _SourceTileState extends State<SourceTile> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: widget.onTap,
        splashColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        onHover: (val) {
          setState(() => hovered = val);
        },
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 100),
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: hovered ? appTheme.backgroundSubColor.withAlpha(242) : appTheme.backgroundSubColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: hovered ? appTheme.accentColor.withAlpha(178) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(38),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.video_library_rounded, color: appTheme.accentColor, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.source.server,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: appTheme.textMainColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "${widget.source.quality} ${widget.source.backup ? '• Backup' : ''}",
                      style: TextStyle(
                        fontSize: 14,
                        color: appTheme.textSubColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: appTheme.textSubColor),
            ],
          ),
        ),
      ),
    );
  }
}
