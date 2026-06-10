import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A sleek indeterminate progress bar — a rounded segment that sweeps left and
/// right over a soft track, with a gradient and rounded caps. The style used by
/// most top-tier apps for "please wait" states.
class AppProgressBar extends StatefulWidget {
  /// Width of the bar. Pass `double.infinity` to fill the parent.
  final double width;
  final double height;
  final Color? color;

  const AppProgressBar({
    super.key,
    this.width = 170,
    this.height = 5,
    this.color,
  });

  @override
  State<AppProgressBar> createState() => _AppProgressBarState();
}

class _AppProgressBarState extends State<AppProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final radius = BorderRadius.circular(widget.height);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackW = constraints.maxWidth;
          final segW = trackW * 0.42;
          return ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                // Track
                Positioned.fill(
                  child: ColoredBox(
                    color: color.withOpacity(isDark ? 0.18 : 0.12),
                  ),
                ),
                // Sweeping segment
                AnimatedBuilder(
                  animation: _t,
                  builder: (context, _) {
                    final left = (trackW - segW) * _t.value;
                    return Positioned(
                      left: left,
                      top: 0,
                      bottom: 0,
                      width: segW,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          gradient: LinearGradient(
                            colors: [color.withOpacity(0.45), color],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Centered inline loading state for pages / lists, with an optional message.
class AppLoading extends StatelessWidget {
  final String? message;
  final double width;

  const AppLoading({super.key, this.message, this.width = 170});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppProgressBar(width: width),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A full-area scrim + card, for overlaying inside a [Stack] (e.g. login).
class AppLoadingOverlay extends StatelessWidget {
  final String? message;

  const AppLoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.35),
        alignment: Alignment.center,
        child: _LoadingCard(message: message),
      ),
    );
  }
}

/// Blocking loading dialog for one-shot actions (export, import, delete, ...).
class AppLoadingDialog {
  /// Shows the dialog. Dismiss with [hide] (or `Navigator.pop`). Not awaited.
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: _LoadingCard(message: message),
      ),
    );
  }

  /// Dismisses the most recent dialog/route.
  static void hide(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).pop();
}

/// The surface card holding the progress bar + optional message, shared by the
/// overlay and the dialog so they look identical.
class _LoadingCard extends StatelessWidget {
  final String? message;
  const _LoadingCard({this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.darkCard : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 26),
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppProgressBar(width: double.infinity),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
