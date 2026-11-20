import 'dart:io';

import 'package:animestream/ui/models/providers/infoProvider.dart';
import 'package:animestream/ui/pages/info/infoDesktop.dart';
import 'package:animestream/ui/pages/info/infoMobile.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

class Info extends StatelessWidget {
  final int id;
  final InfoView initialSection;
  const Info({required this.id, this.initialSection = InfoView.info});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InfoProvider(id, initialSection: initialSection)..init(),
      builder: (context, child) {
        if (Platform.isWindows || Platform.isLinux)
          return InfoDesktop();
        else
          return InfoMobile();
      },
    );
  }
}
