import 'package:flutter/material.dart';

class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        // Base gradient - Figma-inspired dark navy/teal
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark 
                  ? [
                      const Color(0xFF0A1828), // Deep navy
                      const Color(0xFF132D3F), // Dark teal-blue
                      const Color(0xFF1A3A4A), // Medium teal
                    ]
                  : [
                      const Color(0xFFE0C3FC),
                      const Color(0xFF8EC5FC),
                    ],
            ),
          ),
        ),
        // Subtle decorative elements for depth
        if (isDark) ...[
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2A5470).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1E4A5F).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withValues(alpha: 0.3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withValues(alpha: 0.3),
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
                color: Colors.lightBlue.withValues(alpha: 0.3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.lightBlue.withValues(alpha: 0.3),
                    blurRadius: 100,
                    spreadRadius: 20,
                  )
                ]
              ),
            ),
          ),
        ],
        // Content
        SafeArea(child: child),
      ],
    );
  }
}
