import 'package:animestream/ui/theme/types.dart';
import 'package:flutter/material.dart';

/** this is the default theme */

final lime = AnimeStreamTheme(
  accentColor: Color(0xffCAF979),
  backgroundColor: Color.fromARGB(255, 24, 24, 24),
  textMainColor: Colors.white,
  textSubColor: Color.fromARGB(255, 180, 180, 180),
);

/**monochrome theme preset */

final monochrome = AnimeStreamTheme(
  accentColor: Colors.white,
  backgroundColor: Colors.black,
  textMainColor: Colors.white,
  textSubColor: Color.fromARGB(255, 180, 180, 180),
);

/**hotpink accent */

final hotPink = AnimeStreamTheme(
  accentColor: Color(0xffFF69B4),
  backgroundColor: Colors.black,
  textMainColor: Colors.white,
  textSubColor: Color.fromARGB(255, 180, 180, 180),
);