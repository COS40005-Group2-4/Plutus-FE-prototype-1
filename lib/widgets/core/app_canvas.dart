import 'package:flutter/material.dart';
import '../../theme/plutus_tokens.dart';

/// App-wide canvas (spec §5): neutral background plus one very faint
/// radial gold wash bleeding from the top — the only decorative gradient
/// in the app. Replaces the legacy glass background surface.
class AppCanvas extends StatelessWidget {
  final Widget child;

  const AppCanvas({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color wash = t.gold.withValues(alpha: isDark ? 0.04 : 0.05);

    return Stack(
      children: <Widget>[
        Positioned.fill(child: ColoredBox(color: t.bg)),
        Positioned(
          top: -320,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 560,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: <Color>[wash, Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}
