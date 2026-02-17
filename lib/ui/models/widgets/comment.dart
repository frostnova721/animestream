import 'package:animestream/core/app/runtimeDatas.dart';
import 'package:commentum_client/commentum_client.dart';
import 'package:flutter/material.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final CommentumClient client;
  const CommentItem({super.key, required this.comment, required this.client});

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  @override
  void initState() {
    voteState = widget.comment.userVote ?? 0;
    super.initState();
  }

  String _getFriendlyTimeDifference() {
    final diff = DateTime.now().difference(widget.comment.updatedAt);
    if (diff.inDays > 0) return "${diff.inDays} day${diff.inDays > 1 ? "s" : ''} ago";
    if (diff.inHours > 0) return "${diff.inHours} hour${diff.inHours > 1 ? "s" : ''} ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes} minute${diff.inMinutes > 1 ? "s" : ''} ago";
    return "just now";
  }

  late int voteState; // 1 = upvote, 0 = no vote, -1 = downvote

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 15),
      // decoration: BoxDecoration(color: appTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                foregroundImage: widget.comment.avatarUrl != null ? NetworkImage(widget.comment.avatarUrl!) : null,
                backgroundColor: appTheme.backgroundSubColor.withAlpha(80),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.comment.username,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _getFriendlyTimeDifference(),
                      style: TextStyle(fontSize: 12, color: appTheme.textSubColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              widget.comment.content,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _buildVoteButton(
                  icon: Icons.keyboard_arrow_up_rounded,
                  active: voteState == 1,
                  onPressed: () {
                    setState(() {
                      voteState = voteState == 1 ? 0 : 1;
                      widget.comment.upVote(widget.client).catchError((err) {
                        // do nothing for now atleast
                        print(err);
                      });
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text("${widget.comment.score + voteState}"),
                ),
                _buildVoteButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    active: voteState == -1,
                    onPressed: () {
                      setState(() {
                        voteState = voteState == -1 ? 0 : -1;
                        widget.comment.downVote(widget.client).catchError((err) {
                        // do nothing for now atleast
                        print(err);
                      });;
                      });
                    }),
                Spacer(),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: appTheme.backgroundColor, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${widget.comment.repliesCount} "),
                        Icon(Icons.reply_rounded),
                      ],
                    )),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVoteButton({required IconData icon, required bool active, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: Icon(
          icon,
          size: 28,
          color: active ? appTheme.accentColor : appTheme.textSubColor,
        ),
      ),
    );
  }
}
