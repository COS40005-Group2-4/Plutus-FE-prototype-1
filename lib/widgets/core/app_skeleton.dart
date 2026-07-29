import 'package:flutter/material.dart';
import '../../theme/app_elevation.dart';
import '../../theme/plutus_tokens.dart';

/// Neutral loading placeholder (spec §5): a surfaceSubtle slab pulsing
/// gently. Honors reduced motion — under
/// `MediaQuery.disableAnimations` it renders static.
class AppSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const AppSkeleton({super.key, this.width, this.height = 16, this.radius = 6});

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow * 2,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = MediaQuery.of(context).disableAnimations;
    if (reduced) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.55).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: t.surfaceSubtle,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
