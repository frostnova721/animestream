import 'dart:async';

import 'package:flutter/widgets.dart';

class DoubleTapDectector extends StatefulWidget {
  final Widget? child;
  final void Function() onDoubleTap;
  final void Function()? onSingleTap;
  final Duration tapInterval;
  final double tapSlop;
  final HitTestBehavior behavior;
  const DoubleTapDectector({
    super.key,
    required this.onDoubleTap,
    this.onSingleTap,
    this.child,
    this.tapInterval = const Duration(milliseconds: 300), // default flutter time :)
    this.tapSlop = 50,
    this.behavior = HitTestBehavior.deferToChild,
  });

  @override
  State<DoubleTapDectector> createState() => _DoubleTapDectectorState();
}

class _DoubleTapDectectorState extends State<DoubleTapDectector> {
  Timer? _timer;
  int _tapCount = 0;
  DateTime? _lastTapTime;
  Offset? _lastTapOffset;

  void _handlePointerDown(PointerDownEvent ev) {
    final now = DateTime.now();
    final offset = ev.position;
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds <= widget.tapInterval.inMilliseconds &&
        _lastTapOffset != null &&
        (_lastTapOffset! - offset).distance <= widget.tapSlop) {
      _timer?.cancel();
      _tapCount = 0;
      _lastTapTime = null;
      _lastTapOffset = null;

      widget.onDoubleTap.call();
    } else {
      _tapCount = 1;
      _lastTapTime = DateTime.now();
      _lastTapOffset = ev.position;
      _timer?.cancel();

      if (widget.onSingleTap != null) {
        _timer = Timer(widget.tapInterval, () {
          if (_tapCount == 1) {
            widget.onSingleTap?.call();
          }
          _tapCount = 0;
          _lastTapOffset = null;
          _lastTapTime = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: widget.behavior,
      onPointerDown: _handlePointerDown,
      child: widget.child,
    );
  }
}
