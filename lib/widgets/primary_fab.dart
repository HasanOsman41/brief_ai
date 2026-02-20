// lib/widgets/primary_fab.dart
import 'dart:ui';

import 'package:flutter/material.dart';

class PrimaryFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;

  const PrimaryFAB({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Material(
            color: isDark
                ? const Color(0xBF141928).withOpacity(0.9)
                : const Color(0xE5FFFFFF).withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: label != null ? 24 : 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? const Color(0x14FFFFFF)
                        : const Color(0x0F000000),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: primaryColor, size: 24),
                    if (label != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        label!,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}