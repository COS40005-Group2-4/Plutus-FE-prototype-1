import 'package:flutter/material.dart';

class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                  ? [
                      const Color(0xFF0F2027),
                      const Color(0xFF203A43),
                      const Color(0xFF2C5364),
                    ]
                  : [
                      const Color(0xFFE0C3FC),
                      const Color(0xFF8EC5FC),
                    ],
            ),
          ),
        ),
        // Decorative orbs
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? Colors.purple : Colors.purpleAccent).withValues(alpha: 0.3),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.purple : Colors.purpleAccent).withValues(alpha: 0.3),
                  blurRadius: 100,
                  spreadRadius: 20,
                )
              ]
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? Colors.blue : Colors.lightBlue).withValues(alpha: 0.3),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.blue : Colors.lightBlue).withValues(alpha: 0.3),
                  blurRadius: 100,
                  spreadRadius: 20,
                )
              ]
            ),
          ),
        ),
         Positioned(
          top: 200,
          right: 50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? Colors.teal : Colors.tealAccent).withValues(alpha: 0.2),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.teal : Colors.tealAccent).withValues(alpha: 0.2),
                  blurRadius: 80,
                  spreadRadius: 10,
                )
              ]
            ),
          ),
        ),
        // Content
        SafeArea(child: child),
      ],
    );
  }
}
