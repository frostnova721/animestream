import 'package:animestream/core/app/env.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/commentum/commentumTokenStore.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/widgets/comment.dart';
import 'package:animestream/ui/models/widgets/loader.dart';
import 'package:animestream/ui/pages/settingPages/account.dart';
import 'package:commentum_client/commentum_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Commentsection extends StatefulWidget {
  final int mediaId;
  final int? userId;
  // final Databases database;
  const Commentsection({
    super.key,
    required this.mediaId,
    required this.userId,
    // required this.database,
  });

  @override
  State<Commentsection> createState() => _CommentsectionState();
}

class _CommentsectionState extends State<Commentsection> {
  @override
  void initState() {
    super.initState();
    commentum.init().then((_) {
      fetchComments();
    });
    // genfakeComments();
  }

  final commentum = CommentumClient(
    storage: CommentumTokenStore(),
    config: CommentumConfig(
      baseUrl: AnimeStreamEnvironment.commentumApiUrl,
      enableLogging: kDebugMode,
      verboseLogging: kDebugMode,
      appClient: "animestream",
    ),
    preferredProvider: CommentumProvider.anilist,
  );

  final List<CommentumResponse> paginatedComments = [];
  final List<Comment> comments = [];
  // bool reachedEnd = false;

  int? totalComments = null;

  // CommentSortOrder sortType = CommentSortOrder.newest;

  bool errored = false;

  final _textController = TextEditingController();

  String? commentContentCache;

  bool showLogin = false;

  bool loading = false;

  Future<void> fetchComments({String? cursor}) async {
    setState(() {
      loading = true;
    });

    try {
      final res = await commentum.listComments(widget.mediaId.toString(),
          cursor: cursor ?? paginatedComments.lastOrNull?.nextCursor);

      // if (_nextPageCursor == null) reachedEnd = true;
      paginatedComments.add(res);
      comments.addAll(res.data);
      totalComments = res.count;
    } catch (err) {
      print("$err While fetching comments.");
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Comments",
              style: TextStyle(
                color: appTheme.textMainColor,
                fontFamily: "Rubik",
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${totalComments ?? comments.length} items",
              style: TextStyle(color: appTheme.textSubColor, fontFamily: "Rubik"),
            ),
            Expanded(
                child: showLogin
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                            ),
                            Text(
                              "Login to Commentum",
                              style: TextStyle(fontSize: 18, fontFamily: "Poppins"),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                    onPressed: () {
                                      setState(() {
                                        showLogin = false;
                                      });
                                    },
                                    child: Text("nah")),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (!(await AniListLogin().isAnilistLoggedIn())) {
                                      Navigator.pop(context);
                                      Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => AccountSetting()));
                                      floatingSnackBar("Login with anilist first!");
                                    }
                                    await commentum.login(CommentumProvider.anilist,
                                        (await FlutterSecureStorage().read(key: SecureStorageKey.anilistToken.value))!);
                                    if (commentum.isLoggedIn) {
                                      setState(() {
                                        showLogin = false;
                                      });
                                    }
                                  },
                                  child: Text("Login"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: appTheme.accentColor,
                                    foregroundColor: appTheme.onAccent,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    : loading
                        ? Center(
                            child: AnimeStreamLoading(
                            color: appTheme.textMainColor,
                          ))
                        : ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              return CommentItem(comment: comments[index], client: commentum);
                            })),
            Row(
              children: [
                CircleAvatar(
                  foregroundImage: NetworkImage(storedUserData!.avatar!),
                  minRadius: 22,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: TextField(
                      controller: _textController,
                      onTapOutside: (event) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      decoration: InputDecoration(
                        hintText: "comment as ${storedUserData!.name}",
                        hintStyle: TextStyle(fontSize: 14, fontFamily: "NotoSans", color: appTheme.textSubColor),
                        focusColor: appTheme.accentColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: appTheme.textMainColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: appTheme.textMainColor),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: appTheme.textMainColor),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      ),
                    ),
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: _textController,
                  builder: (context, value, child) {
                    return IconButton.filled(
                      onPressed: value.text.isEmpty
                          ? null
                          : () async {
                              if (!commentum.isLoggedIn) {
                                setState(() {
                                  showLogin = true;
                                });
                                return;
                              }

                              final content = _textController.text.trim();
                              commentContentCache = content;
                              _textController.clear();

                              try {
                                final cmt = await commentum.createComment(
                                  widget.mediaId.toString(),
                                  "anilist",
                                  content,
                                );
                                comments.add(cmt);
                              } catch (e) {
                                errored = true;
                                commentContentCache = content;
                              }

                              setState(() {});
                            },
                      icon: Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(
                          backgroundColor: appTheme.textMainColor,
                          foregroundColor: appTheme.backgroundColor,
                          disabledForegroundColor: appTheme.backgroundColor,
                          disabledBackgroundColor: appTheme.textMainColor.withAlpha(80)),
                    );
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
