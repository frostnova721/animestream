import 'package:animestream/core/app/env.dart';
import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:animestream/core/database/commentum/commentumTokenStore.dart';
import 'package:animestream/ui/models/widgets/comment.dart';
import 'package:commentum_client/commentum_client.dart';
import 'package:commentum_client/src/models/response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    genfakeComments();
    // fetchComments();
  }

  final commentum = CommentumClient(
    storage: CommentumTokenStore(),
    config: CommentumConfig(
      baseUrl: AnimeStreamEnvironment.commentumApiUrl,
      enableLogging: kDebugMode,
    ),
  );

  final List<CommentumResponse> paginatedComments = [];
  final List<Comment> comments = [];
  // bool reachedEnd = false;

  int? totalComments = null;

  // CommentSortOrder sortType = CommentSortOrder.newest;

  bool errored = false;

  final _textController = TextEditingController();

  void genfakeComments() {
    final msgs = [
      "goated anime",
      "ts so trash",
      "wasted my time lmao",
      "who ever drew ts needs a raise",
      "the mc is so based",
      "the op slaps",
      "the ed is a bop",
      "the animation is god tier",
      "the story is so good",
      "the characters are so well written",
      "fuck this anime and everyone who likes it.asdddddddddddddddddddddddddddddddddddddddddddddddddd",
    ];

    final usernames = [
      "animeFan123",
      "otakuGirl",
      "mangaLover",
      "weebMaster",
      "kawaiiSenpai",
      "shonenKing",
      "shojoQueen",
      "animeAddict",
      "cosplayPro",
      "animeCritic",
      "niggasOnMyAnime",
    ];

    for (int i = 0; i < msgs.length; i++) {
      comments.add(Comment(
        id: i.toString(),
        createdAt: DateTime.now().subtract(Duration(minutes: i * 5)),
        hasMoreReplies: false,
        replies: [],
        repliesCount: 0,
        score: i * 5,
        userVote: i % 2 == 0 ? 1 : -1,
        status: CommentStatus.active,
        content: msgs[i],
        username: usernames[i],
        avatarUrl: "https://i.pravatar.cc/150?img=$i",
        updatedAt: DateTime.now().subtract(Duration(minutes: i * 5)),
      ));
    }
  }

  Future<void> fetchComments({String? cursor}) async {
    final res = await commentum.listComments(widget.mediaId.toString(),
        cursor: cursor ?? paginatedComments.lastOrNull?.nextCursor);

    // if (_nextPageCursor == null) reachedEnd = true;
    paginatedComments.add(res);
    comments.addAll(res.data);
    totalComments = res.count;

    setState(() {});
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
              child: ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    return CommentItem(comment: comments[index]);
                  }),
            ),
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
                        // suffixIcon: Container(
                        //   decoration: BoxDecoration(
                        //     borderRadius: BorderRadius.circular(14),
                        //     // color: appTheme.textMainColor,
                        //   ),
                        //   clipBehavior: Clip.antiAlias,
                        //   child: Material(
                        //     color: Colors.transparent,
                        //     child: InkWell(
                        //       onTap: () {},
                        //       child: Icon(
                        //         Icons.send_rounded,
                        //         color: appTheme.backgroundColor,
                        //       ),
                        //     ),
                        //   ),
                        // ),
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
                              try {
                                // final cmt = await commentum.createComment(
                                //     widget.mediaId.toString(), _textController.text.trim());

                                final cmt = Comment(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  content: value.text.trim(),
                                  score: 0,
                                  status: CommentStatus.active,
                                  username: storedUserData!.name,
                                  avatarUrl: storedUserData!.avatar,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  replies: [],
                                  hasMoreReplies: false,
                                  repliesCount: 0,
                                  userVote: null,
                                );

                                comments.add(cmt);
                                _textController.clear();
                              } catch (e) {
                                setState(() {
                                  errored = true;
                                });
                              }
                            },
                      icon: Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(
                          backgroundColor: appTheme.textMainColor,
                          foregroundColor: appTheme.backgroundColor,
                          disabledForegroundColor: appTheme.backgroundColor,
                          disabledBackgroundColor: appTheme.textMainColor.withAlpha(80)
                          // shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
                          ),
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
