import 'package:commentum/commentum.dart';
import 'package:flutter/widgets.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  const CommentItem({super.key, required this.comment});

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.comment.username),
        Text(widget.comment.content),
      ],
    );
  }
}