import 'package:flutter/material.dart';

class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: Theme.of(context).scaffoldBackgroundColor),
          Positioned(
            top: -120,
            right: -80,
            child: _Blob(
              size: 280,
              color: primary.withOpacity(isDark ? 0.22 : 0.18),
            ),
          ),
          Positioned(
            top: 80,
            left: -100,
            child: _Blob(
              size: 220,
              color: secondary.withOpacity(isDark ? 0.18 : 0.14),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -120,
            child: _Blob(
              size: 320,
              color: primary.withOpacity(isDark ? 0.14 : 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}
