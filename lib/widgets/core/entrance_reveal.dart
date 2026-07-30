import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';

/// One orchestrated entrance (spec §8): the child rises 10px and fades in
/// over [AppMotion.slow], delayed 40ms per [index] so sibling blocks
/// cascade header → hero → cards. Skipped entirely under reduced motion.
class EntranceReveal extends StatefulWidget {
  final int index;
  final Widget child;

  const EntranceReveal({super.key, required this.index, required this.child});

  @override
  State<EntranceReveal> createState() => _EntranceRevealState();
}

class _EntranceRevealState extends State<EntranceReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _controller, curve: AppMotion.emphasized);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1.0;
    } else {
      Future<void>.delayed(Duration(milliseconds: 40 * widget.index), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (BuildContext context, Widget? child) => Transform.translate(
          offset: Offset(0, 10 * (1 - _curve.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
