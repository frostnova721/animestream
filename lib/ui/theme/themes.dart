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

//NO! JUST NO
final lightcaf = AnimeStreamTheme(
  accentColor: Color(0xffcaf979),
  backgroundColor: Colors.white,
  textMainColor: Colors.black,
  textSubColor: Color.fromARGB(255, 143, 143, 143),
);

/**Cold Purple accent */
final coldPurple = AnimeStreamTheme(
  accentColor: Color(0xff9D8ABF),
  backgroundColor: Colors.black,
  textMainColor: Colors.white,
  textSubColor: Color.fromARGB(255, 180, 180, 180),
);
