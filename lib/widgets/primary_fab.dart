// lib/widgets/primary_fab.dart
import 'dart:ui';

import 'package:brief_ai/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PrimaryFAB extends StatefulWidget {
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
  State<PrimaryFAB> createState() => _PrimaryFABState();
}

class _PrimaryFABState extends State<PrimaryFAB> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _entranceController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for press effect
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Rotation animation for icon
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );

    // Continuous pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Entrance animation
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _entranceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _onPressed() {
    // Play press animations
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    _rotateController.forward().then((_) {
      _rotateController.reset();
    });

    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _rotateAnimation,
        _pulseAnimation,
        _entranceAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _entranceAnimation.value)),
          child: Opacity(
            opacity: _entranceAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(
                        0.3 + 0.2 * _pulseAnimation.value,
                      ),
                      blurRadius: 20 + 10 * _pulseAnimation.value,
                      spreadRadius: 0 + 5 * _pulseAnimation.value,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Material(
                      color: isDark
                          ? AppTheme.darkSurface.withOpacity(0.9)
                          : AppTheme.lightSurface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      child: InkWell(
                        onTap: _onPressed,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.label != null ? 24 : 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.lightBorder,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.rotate(
                                angle:
                                    _rotateAnimation.value * 6.28, // 2π radians
                                child: Icon(
                                  widget.icon,
                                  color: primaryColor,
                                  size: 24,
                                ),
                              ),
                              if (widget.label != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  widget.label!,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.lightTextPrimary,
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
              ),
            ),
          ),
        );
      },
    );
  }
}
