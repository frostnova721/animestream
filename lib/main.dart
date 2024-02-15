import 'dart:io';

import 'package:animestream/ui/pages/home.dart';
import 'package:animestream/ui/theme/mainTheme.dart';
import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Directory dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animestream',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: themeColor),
      ),
      home: AnimatedSplashScreen(
        splash: Image.asset("lib/assets/icons/logo_transparent.png"),
        nextScreen: const Home(),
        duration: 1000,
        backgroundColor: Color(0xFF191918),
        animationDuration: Durations.long1,
        splashTransition: SplashTransition.fadeTransition,
        pageTransitionType: PageTransitionType.rightToLeft,
        centered: true,
        splashIconSize: 150,
      ),
      // home: MyWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}