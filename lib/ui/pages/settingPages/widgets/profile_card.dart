import 'dart:ui';

import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/database/anilist/types.dart';
import 'package:animestream/ui/pages/settingPages/stats.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final UserModal? userModal;
  final VoidCallback onLogout;
  final String accountName;

  const ProfileCard({
    super.key,
    required this.userModal,
    required this.onLogout,
    required this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (userModal != null && userModal!.id != -1) {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => UserStats(userModal: userModal!)));
        }
      },
      child: ClipRRect(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: userModal?.banner != null
                        ? NetworkImage(userModal!.banner!)
                        : const AssetImage('lib/assets/images/profile_banner.jpg') as ImageProvider,
                    fit: BoxFit.cover,
                    opacity: 0.5,
                  ),
                ),
              ),
            ),
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withAlpha(180), Colors.black.withAlpha(40)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: userModal?.avatar != null
                        ? NetworkImage(userModal!.avatar!)
                        : const AssetImage("lib/assets/images/ghost.png") as ImageProvider,
                    radius: 30,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userModal?.name ?? "Unknown User",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 18,
                            color: appTheme.textMainColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          accountName.toUpperCase(),
                          style: TextStyle(
                            color: appTheme.textSubColor,
                            fontFamily: "Rubik",
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onLogout,
                    icon: Row(
                      children: [
                        Icon(Icons.logout, color: appTheme.textMainColor, size: 22),
                        Text(
                          " Logout",
                          style: TextStyle(fontFamily: "Rubik", color: appTheme.textMainColor),
                        ),
                      ],
                    ),
                    tooltip: "Logout",
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(30),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
