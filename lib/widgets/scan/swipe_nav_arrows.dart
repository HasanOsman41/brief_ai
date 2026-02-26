// lib/widgets/scan/swipe_nav_arrows.dart
import 'package:flutter/material.dart';

/// Left / right arrow overlays for page-by-page navigation.
class SwipeNavArrows extends StatelessWidget {
  const SwipeNavArrows({
    super.key,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
  });

  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          canGoBack
              ? _Arrow(icon: Icons.chevron_left, onTap: onBack)
              : const SizedBox(width: 56),
          canGoForward
              ? _Arrow(icon: Icons.chevron_right, onTap: onForward)
              : const SizedBox(width: 56),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          size: 40,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black38, blurRadius: 10)],
        ),
      ),
    );
  }
}
