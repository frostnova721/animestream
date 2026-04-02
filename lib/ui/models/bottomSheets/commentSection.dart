import 'package:animestream/core/app/env.dart';
import 'package:animestream/core/app/logging.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/commons/enums.dart';
import 'package:animestream/core/database/anilist/login.dart';
import 'package:animestream/core/database/commentum/commentumTokenStore.dart';
import 'package:animestream/ui/models/snackBar.dart';
import 'package:animestream/ui/models/widgets/comment.dart';
import 'package:animestream/ui/models/widgets/loader.dart';
import 'package:animestream/ui/pages/settingPages/account.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  bool replyMode = false;

  int? activeCommentIndex;

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

  void showLoginDialog() {
    setState(() {
      showLogin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !replyMode,
      onPopInvokedWithResult: (didPop, result) {
        setState(() {
          if (replyMode) replyMode = false;
        });
      },
      child: Padding(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        replyMode ? "Replies" : "Comments",
                        style: TextStyle(
                          color: appTheme.textMainColor,
                          fontFamily: "Rubik",
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${replyMode ? comments[activeCommentIndex!].replies.length : totalComments ?? comments.length} items",
                        style: TextStyle(color: appTheme.textSubColor, fontFamily: "Rubik"),
                      ),
                    ],
                  ),
                  if (replyMode)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          replyMode = false;
                        });
                      },
                      icon: Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                ],
              ),
              Expanded(
                  child: showLogin
                      ? _loginDialog()
                      : loading
                          ? Center(
                              child: AnimeStreamLoading(
                              color: appTheme.textMainColor,
                            ))
                          : replyMode
                              ? ListView.builder(
                                  itemCount: comments[activeCommentIndex!].replies.length,
                                  itemBuilder: (context, index) {
                                    return CommentItem(
                                      comment: comments[activeCommentIndex!].replies[index],
                                      client: commentum,
                                      replyMode: true,
                                      showLoginDialog: showLoginDialog,
                                    );
                                  })
                              : ListView.builder(
                                  itemCount: comments.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () {
                                          if (kDebugMode)
                                            setState(() {
                                              activeCommentIndex = index;
                                              replyMode = true;
                                            });
                                        },
                                        child: CommentItem(
                                          comment: comments[index],
                                          client: commentum,
                                          showLoginDialog: showLoginDialog,
                                        ));
                                  })),
              if (!showLogin)
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
                            hintText: replyMode
                                ? "reply to @${comments[activeCommentIndex!].username}"
                                : "comment as ${storedUserData!.name}",
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
                                  // if (replyMode) return print("${comments[activeCommentIndex!].parentId}");
                                  if (!commentum.isLoggedIn) {
                                    print("Not logged in with commentum.");
                                    setState(() {
                                      showLogin = true;
                                    });
                                    return;
                                  }

                                  final content = _textController.text.trim();
                                  commentContentCache = content;
                                  _textController.clear();

                                  try {
                                    if (replyMode) {
                                      final cmt =
                                          await commentum.createReply(comments[activeCommentIndex!].id, content);
                                      // print("cmt: $cmt");
                                      comments[activeCommentIndex!].replies.add(cmt);
                                    } else {
                                      final cmt = await commentum.createComment(
                                        widget.mediaId.toString(),
                                        "anilist",
                                        content,
                                      );
                                      comments.add(cmt);
                                    }
                                  } catch (e) {
                                    errored = true;
                                    _textController.text = content;
                                    Logs.app.log(e.toString());
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
      ),
    );
  }

  bool loggingIn = false;

  Widget _loginDialog() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox.shrink(),
        Center(
          child: loggingIn
              ? Text(
                  "Logging in...",
                  style: TextStyle(fontSize: 18, fontFamily: "Rubik"),
                )
              : Column(
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
                            setState(() {
                              loggingIn = true;
                            });

                            if (!(await AniListLogin().isAnilistLoggedIn())) {
                              Navigator.pop(context);
                              Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => AccountSetting()));
                              floatingSnackBar("Login with anilist first!");
                            }
                            await commentum
                                .login(CommentumProvider.anilist,
                                    (await FlutterSecureStorage().read(key: SecureStorageKey.anilistToken.value))!)
                                .onError((er, st) {});

                            setState(() {
                              loggingIn = false;
                              showLogin = !commentum.isLoggedIn;
                            });
                          },
                          child: Text("Login"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appTheme.accentColor,
                            foregroundColor: appTheme.onAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              foregroundImage: CachedNetworkImageProvider(storedUserData!.avatar!),
              radius: 15,
            ),
            Text(
              " @${storedUserData!.name}",
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          ],
        ),
      ],
    );
  }
}
