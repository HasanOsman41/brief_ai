import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum SnackbarType { success, error, warning, info }

/// Unified, animated snackbar used across the whole app.
///
/// Prefer the shorthand helpers for the common cases:
/// ```dart
/// ProfessionalSnackbar.success(context, 'Saved');
/// ProfessionalSnackbar.error(context, 'Something went wrong');
/// ```
class ProfessionalSnackbar {
  static void show({
    required BuildContext context,
    String? title,
    required String message,
    SnackbarType type = SnackbarType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: _AnimatedSnackContent(
          title: title,
          message: message,
          type: type,
          duration: duration,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  // ── Shorthand helpers ──────────────────────────────────────
  static void success(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) => show(
    context: context,
    message: message,
    title: title,
    type: SnackbarType.success,
    duration: duration,
  );

  static void error(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) => show(
    context: context,
    message: message,
    title: title,
    type: SnackbarType.error,
    duration: duration,
  );

  static void warning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) => show(
    context: context,
    message: message,
    title: title,
    type: SnackbarType.warning,
    duration: duration,
  );

  static void info(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) => show(
    context: context,
    message: message,
    title: title,
    type: SnackbarType.info,
    duration: duration,
  );
}

class _AnimatedSnackContent extends StatefulWidget {
  final String? title;
  final String message;
  final SnackbarType type;
  final Duration duration;

  const _AnimatedSnackContent({
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
  });

  @override
  State<_AnimatedSnackContent> createState() => _AnimatedSnackContentState();
}

class _AnimatedSnackContentState extends State<_AnimatedSnackContent>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _iconScale;

  // Drives the depleting "time remaining" bar.
  late final AnimationController _timer;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
    _fade = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.45), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entry,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );
    _iconScale = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.15, 1.0, curve: Curves.elasticOut),
    );

    _timer = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    _timer.dispose();
    super.dispose();
  }

  Color _accent(bool isDark) {
    switch (widget.type) {
      case SnackbarType.success:
        return isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess;
      case SnackbarType.error:
        return isDark ? AppTheme.darkDanger : AppTheme.lightDanger;
      case SnackbarType.warning:
        return isDark ? AppTheme.darkWarning : AppTheme.lightWarning;
      case SnackbarType.info:
        return isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case SnackbarType.success:
        return Icons.check_circle_rounded;
      case SnackbarType.error:
        return Icons.error_rounded;
      case SnackbarType.warning:
        return Icons.warning_rounded;
      case SnackbarType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(isDark);
    final surface = isDark ? AppTheme.darkCard : Colors.white;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final hasTitle = widget.title != null && widget.title!.isNotEmpty;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.40 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Direction-aware accent strip.
                  Container(width: 4, color: accent),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ScaleTransition(
                                scale: _iconScale,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_icon, color: accent, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (hasTitle) ...[
                                      Text(
                                        widget.title!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                    Text(
                                      widget.message,
                                      style: TextStyle(
                                        fontSize: hasTitle ? 12.5 : 13.5,
                                        height: 1.3,
                                        fontWeight: hasTitle
                                            ? FontWeight.w400
                                            : FontWeight.w600,
                                        color: hasTitle
                                            ? onSurface.withOpacity(0.75)
                                            : onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkResponse(
                                onTap: () => ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar(),
                                radius: 18,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: onSurface.withOpacity(0.55),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Depleting time-remaining bar.
                        AnimatedBuilder(
                          animation: _timer,
                          builder: (context, _) => Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FractionallySizedBox(
                              widthFactor: (1.0 - _timer.value).clamp(0.0, 1.0),
                              child: Container(
                                height: 3,
                                color: accent.withOpacity(0.55),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
