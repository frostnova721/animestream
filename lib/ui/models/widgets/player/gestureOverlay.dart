import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class GestureOverlay extends StatefulWidget {
  final Widget child;
  // Feature Flags
  final bool isDesktop;
  final bool controlsLocked;
  final bool enableHoldToSpeedUp;

  // Hover & Tap Callbacks
  final void Function(PointerHoverEvent) onPointerHover;
  final VoidCallback onSingleTap;

  // Double Tap Callbacks (Split by zones)
  final VoidCallback onDoubleTapLeft;
  final VoidCallback onDoubleTapCenter;
  final VoidCallback onDoubleTapRight;

  // Speed Control Callbacks (Long Press + Horizontal Drag)
  final VoidCallback onSpeedUpStart;
  final void Function(bool increase) onSpeedChange;
  final VoidCallback onSpeedUpEnd;

  // Volume & Brightness Callbacks (Vertical Drag)
  final Future<double> Function() getInitialVolume;
  final Future<double> Function() getInitialBrightness;
  final void Function(double) onVolumeUpdate;
  final void Function(double) onBrightnessUpdate;
  final VoidCallback onVerticalDragEnd;

  const GestureOverlay({
    super.key,
    required this.child,
    required this.isDesktop,
    required this.controlsLocked,
    required this.enableHoldToSpeedUp,
    required this.onPointerHover,
    required this.onSingleTap,
    required this.onDoubleTapLeft,
    required this.onDoubleTapCenter,
    required this.onDoubleTapRight,
    required this.onSpeedUpStart,
    required this.onSpeedChange,
    required this.onSpeedUpEnd,
    required this.getInitialVolume,
    required this.getInitialBrightness,
    required this.onVolumeUpdate,
    required this.onBrightnessUpdate,
    required this.onVerticalDragEnd,
  });

  @override
  State<GestureOverlay> createState() => _GestureOverlayState();
}

class _GestureOverlayState extends State<GestureOverlay> {
    // Tap State
  Timer? _tapTimer;

  bool _waitingForSecondTap = false;

  Offset? _lastTapPosition;

  final int _doubleTapThreshold = 300; 
 // ms
  bool _isSpeedingUp = false;

  double? _lastSpeedChangeOffset;

  // Vertical Drag (Volume/Brightness) State
  double? _dragStartY;

  double? _startValue;

  bool _isLeftHalfDrag = false;

  final double _verticalDragSensitivity = 300.0;

  void _handleTapDown(TapDownDetails details) {
    _lastTapPosition = details.localPosition;
  }

  void _handleTap() {
    if (_waitingForSecondTap && _lastTapPosition != null) {
      _waitingForSecondTap = false;
      _tapTimer?.cancel();
      
      // Calculate which third of the screen was double-tapped
      final screenWidth = MediaQuery.sizeOf(context).width;
      final tapX = _lastTapPosition!.dx;
      
      if (tapX < screenWidth * 0.33) {
        widget.onDoubleTapLeft();
      } else if (tapX > screenWidth * 0.66) {
        widget.onDoubleTapRight();
      } else {
        widget.onDoubleTapCenter();
      }
      return;
    }

    widget.onSingleTap();
    _waitingForSecondTap = true;
    
    _tapTimer = Timer(Duration(milliseconds: _doubleTapThreshold), () {
      if (mounted) setState(() => _waitingForSecondTap = false);
    });
  }

  // --- VERTICAL DRAG (Volume / Brightness) ---
  void _onVerticalDragStart(DragStartDetails details) async {
    if (widget.controlsLocked) return;
    
    final screenWidth = MediaQuery.sizeOf(context).width;
    _dragStartY = details.localPosition.dy;
    _isLeftHalfDrag = details.localPosition.dx < (screenWidth / 2);

    if (_isLeftHalfDrag) {
      _startValue = await widget.getInitialBrightness();
    } else {
      _startValue = await widget.getInitialVolume();
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (widget.controlsLocked || _dragStartY == null || _startValue == null) return;

    final double dragDistance = _dragStartY! - details.localPosition.dy;
    final double changePercentage = dragDistance / _verticalDragSensitivity;
    final double newValue = (_startValue! + changePercentage).clamp(0.0, 1.0);

    if (_isLeftHalfDrag) {
      widget.onBrightnessUpdate(newValue);
    } else {
      widget.onVolumeUpdate(newValue);
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _dragStartY = null;
    _startValue = null;
    widget.onVerticalDragEnd();
  }

  // --- LONG PRESS (Speed Control) ---
  void _onLongPressStart(LongPressStartDetails details) {
    if (widget.isDesktop || widget.controlsLocked || !widget.enableHoldToSpeedUp) return;
    
    _isSpeedingUp = true;
    _lastSpeedChangeOffset = null;
    widget.onSpeedUpStart();
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (widget.isDesktop || !_isSpeedingUp) return;

    final offset = details.localOffsetFromOrigin.dx;
    if (_lastSpeedChangeOffset == null) {
      _lastSpeedChangeOffset = offset;
      return;
    }

    final delta = (offset - _lastSpeedChangeOffset!).abs();
    if (delta >= 40) { // 40px threshold to snap to next speed
      widget.onSpeedChange(offset > _lastSpeedChangeOffset!);
      _lastSpeedChangeOffset = offset;
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_isSpeedingUp || widget.isDesktop) return;
    _isSpeedingUp = false;
    _lastSpeedChangeOffset = null;
    widget.onSpeedUpEnd();
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerHover: widget.onPointerHover,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: _handleTapDown,
        onTap: _handleTap,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onLongPressStart: _onLongPressStart,
        onLongPressMoveUpdate: _onLongPressMoveUpdate,
        onLongPressEnd: _onLongPressEnd,
        child: widget.child,
      ),
    );
  }
}
