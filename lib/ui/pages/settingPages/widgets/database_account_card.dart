import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/pages/settingPages/widgets/login_card.dart';
import 'package:animestream/ui/pages/settingPages/widgets/profile_card.dart';
import 'package:flutter/material.dart';

class DatabaseAccountCard extends StatelessWidget {
  final String databaseName;
  final bool loggedIn;
  final UserModal? userModal;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  const DatabaseAccountCard({
    super.key,
    required this.databaseName,
    required this.loggedIn,
    this.userModal,
    required this.onLogin,
    required this.onLogout,
  });

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final name = _capitalize(databaseName);
    return Container(
      width: 400, // Fixed max width for desktop layout
      // margin: const EdgeInsets.only(bottom: 12),
      child: loggedIn
          ? ProfileCard(
              userModal: userModal,
              onLogout: onLogout,
              accountName: name,
            )
          : LoginCard(
              onLogin: onLogin,
              accountName: name,
            ),
    );
  }
}
