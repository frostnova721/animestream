import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';

Widget topRow(BuildContext context, String title) {
  return Row(
    children: [
      IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(
          Icons.arrow_back_rounded,
          color: textMainColor,
          size: 32,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: "Rubik",
            fontSize: 23,
            color: textMainColor,
          ),
        ),
      ),
    ],
  );
}

PreferredSizeWidget settingPagesAppBar(BuildContext context) {
  return PreferredSize(
    preferredSize: Size(double.infinity, 70),
    child: Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: MediaQuery.of(context).padding.left + 10,
        right: MediaQuery.of(context).padding.right + 10,
        bottom: 10,
      ),
      child: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_rounded,
            color: textMainColor,
            size: 35,
          )),
    ),
  );
}

Widget settingPagesTitleHeader(BuildContext context, String title) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(
          // top: 5,
          left: 10,
          right: 10,
          bottom: 10,
        ),
        child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_rounded,
              color: textMainColor,
              size: 35,
            )),
      ),
      Container(
        padding: EdgeInsets.only(top: 40, left: 20, bottom: 40),
        child: Text(
          title,
          style: TextStyle(fontFamily: "Rubik", fontSize: 40),
        ),
      ),
    ],
  );
}

TextStyle textStyle() {
  return TextStyle(
    color: textMainColor,
    fontFamily: "NotoSans",
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );
}

EdgeInsets pagePadding(BuildContext context, {bool bottom = false}) {
  final paddingQuery = MediaQuery.of(context).padding;
  return EdgeInsets.only(
    top: paddingQuery.top + 10,
    left: paddingQuery.left,
    right: paddingQuery.right,
    bottom: bottom ? paddingQuery.bottom : 0,
  );
}

class RoundedRectangularThumbShape extends SliderComponentShape {
  final double width;
  final double radius;
  final double height;

  RoundedRectangularThumbShape({required this.width, this.radius = 4, this.height = 25});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(width, 10);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = backgroundSubColor,
    );

    final strokeRect = Rect.fromCenter(center: center, width: width, height: height);
    context.canvas.drawRRect(
        RRect.fromRectAndRadius(strokeRect, Radius.circular(radius)),
        Paint()
          ..color = textMainColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  }
}

/**Inspired design from saikou/dantotsu */
//looks great ngl
class MarginedTrack extends SliderTrackShape {
  const MarginedTrack();

  @override
  Rect getPreferredRect(
      {required RenderBox parentBox,
      Offset offset = Offset.zero,
      required SliderThemeData sliderTheme,
      bool isEnabled = true,
      bool isDiscrete = true}) {
    final double overlayWidth = sliderTheme.overlayShape!.getPreferredSize(isEnabled, isDiscrete).width;
    final double trackHeight = sliderTheme.trackHeight ?? 20;
    assert(overlayWidth >= 0);
    assert(trackHeight >= 0);
    assert(parentBox.size.width >= overlayWidth);
    assert(parentBox.size.height >= trackHeight);

    final double trackLeft = offset.dx + overlayWidth / 2;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - overlayWidth;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(PaintingContext context, Offset offset,
      {required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required Animation<double> enableAnimation,
      required Offset thumbCenter,
      Offset? secondaryOffset,
      bool isEnabled = true,
      bool isDiscrete = true,
      required TextDirection textDirection}) {
    final ColorTween activeTrackColorTween =
        ColorTween(begin: sliderTheme.disabledActiveTrackColor, end: sliderTheme.activeTrackColor);
    final ColorTween inactiveTrackColorTween =
        ColorTween(begin: sliderTheme.disabledInactiveTrackColor, end: sliderTheme.inactiveTrackColor);

    final Paint activePaint = Paint()..color = activeTrackColorTween.evaluate(enableAnimation)!;
    final Paint inactivePaint = Paint()..color = inactiveTrackColorTween.evaluate(enableAnimation)!;

    Paint leftTrackPaint;
    Paint rightTrackPaint;

    switch (textDirection) {
      case TextDirection.ltr:
        leftTrackPaint = activePaint;
        rightTrackPaint = inactivePaint;
        break;
      case TextDirection.rtl:
        leftTrackPaint = inactivePaint;
        rightTrackPaint = activePaint;
        break;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Rect leftTrackSegment = Rect.fromLTRB(trackRect.left, trackRect.top, thumbCenter.dx - 12, trackRect.bottom);
    final Rect rightTrackSegment = Rect.fromLTRB(thumbCenter.dx + 12, trackRect.top, trackRect.right, trackRect.bottom);

    context.canvas.drawRRect(RRect.fromRectAndRadius(leftTrackSegment, Radius.circular(5)), leftTrackPaint);
    context.canvas.drawRRect(RRect.fromRectAndRadius(rightTrackSegment, Radius.circular(5)), rightTrackPaint);
  }
}

class RoundedSliderValueIndicator extends SliderComponentShape {
  final double width;
  final double height;
  final double radius;
  final bool onBottom;

  RoundedSliderValueIndicator({required this.width, required this.height, this.radius = 5, this.onBottom = false});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(width, height);
  }

  // String getValue(double value) {
  //   return (min+(max-min)*value).toString();
  // }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final verticalValue = onBottom ? 35 : -35;
    final centerWithVerticalOffset = Offset(center.dx, center.dy + verticalValue);

    final rect = Rect.fromCenter(center: centerWithVerticalOffset, height: height, width: width);

    final TextPainter tp = labelPainter;

    tp.layout();

    context.canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), Paint()..color = accentColor);
    tp.paint(context.canvas, Offset(center.dx - (tp.width /2) ,centerWithVerticalOffset.dy - (tp.height / 2)));
  }
}
