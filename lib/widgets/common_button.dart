import 'package:flutter/material.dart';

class CommonButton extends StatefulWidget {
  const CommonButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.isPrimary = true,
    this.withPulse = false,
    this.width,
    this.height,
  });

  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isPrimary;
  final bool withPulse;
  final double? width;
  final double? height;

  @override
  State<CommonButton> createState() => _CommonButtonState();
}

class _CommonButtonState extends State<CommonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.withPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final surface = colorScheme.surface;
    final onPrimary = colorScheme.onPrimary;
    final onSurface = colorScheme.onSurface;
    final isEnabled = widget.onTap != null;

    Widget button = GestureDetector(
      onTap: isEnabled ? widget.onTap : null,
      child: Container(
        width: widget.width,
        height: widget.height ?? 50,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: widget.isPrimary && isEnabled
              ? LinearGradient(
                  colors: [primary.withOpacity(0.75), primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: widget.isPrimary
              ? (isEnabled ? null : onPrimary.withOpacity(0.12))
              : surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: widget.isPrimary && isEnabled
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                color: isEnabled
                    ? (widget.isPrimary ? onPrimary : onSurface)
                    : onSurface.withOpacity(0.38),
                size: 20,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              widget.text,
              style: TextStyle(
                color: isEnabled
                    ? (widget.isPrimary ? onPrimary : onSurface)
                    : onSurface.withOpacity(0.38),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.withPulse) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _pulseAnimation.value, child: button);
        },
      );
    }

    return button;
  }
}
