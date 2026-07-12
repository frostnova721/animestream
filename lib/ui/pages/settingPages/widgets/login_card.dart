import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:flutter/material.dart';

class LoginCard extends StatelessWidget {
  final VoidCallback onLogin;
  final String accountName;

  const LoginCard({
    super.key,
    required this.onLogin,
    required this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: appTheme.backgroundSubColor,
        border: Border.all(color: appTheme.accentColor.withAlpha(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  accountName,
                  style: TextStyle(
                    color: appTheme.textMainColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Not logged in",
                  style: TextStyle(
                    color: appTheme.textSubColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onLogin,
            icon: Icon(Icons.login, color: appTheme.accentColor, size: 20),
            label: Text(
              "Log In",
              style: TextStyle(
                color: appTheme.accentColor,
                fontFamily: "NotoSans",
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.backgroundColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: appTheme.accentColor, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
