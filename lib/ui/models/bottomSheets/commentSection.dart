import 'package:animestream/ui/models/widgets/comment.dart';
import 'package:commentum/commentum.dart';
import 'package:flutter/widgets.dart';

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
    fetchComments();
  }

  final commentum = CommentumClient();

  final List<Comment> comments = [];
  MediaResponse? mediaResponse;

  CommentSortOrder sortType = CommentSortOrder.newest;

  Future<void> fetchComments() async {
    // rn only anilist, cus animestream focuses of anilist as primary source.
    final res = await commentum.media.getMediaComments(
      mediaId: widget.mediaId.toString(),
      clientType: ClientType.anilist,
      sort: sortType,
    );

    setState(() {
      mediaResponse = res;
      comments.addAll(res.comments); // memory waste? idc
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Comments"),
        Text("${mediaResponse?.stats.commentCount ?? "??"} items"),
        Expanded(
          child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                return CommentItem(comment: comments[index]);
              }),
        ),
      ],
    );
  }
}
