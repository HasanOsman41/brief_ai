// lib/widgets/glass_card.dart
import 'dart:ui';

import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool hasBorder;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.onTap,
    this.hasBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder ? Border.all(
          color: isDark 
              ? const Color(0x14FFFFFF) 
              : const Color(0x0F000000),
          width: 1,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.45) 
                : Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xBF141928) // rgba(20,25,40,0.75)
                  : const Color(0xE5FFFFFF), // 90% white
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}