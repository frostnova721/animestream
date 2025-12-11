import 'dart:io';

import 'package:animestream/ui/models/widgets/player/desktopControls/desktopControls.dart';
import 'package:animestream/ui/models/widgets/player/mobileControls/mobileControls.dart';
import 'package:flutter/material.dart';

/// A wrapper class for selecting platform-specific controls
class Controls extends StatelessWidget {
  const Controls({super.key});

  @override
  Widget build(BuildContext context) {
    return Platform.isAndroid || Platform.isIOS
        ? const MobileControls()
        : const DesktopControls();
  }
}