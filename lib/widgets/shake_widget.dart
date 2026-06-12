import 'package:flutter/material.dart';

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final ShakeController controller;

  const ShakeWidget({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _anim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    widget.controller._attach(this);
  }

  void shake() => _ctrl.forward(from: 0);

  @override
  void dispose() {
    widget.controller._detach(this);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Transform.translate(
        offset: Offset(_anim.value, 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class ShakeController {
  _ShakeWidgetState? _state;

  void _attach(_ShakeWidgetState state) => _state = state;
  void _detach(_ShakeWidgetState state) {
    if (_state == state) _state = null;
  }

  void shake() => _state?.shake();
}
