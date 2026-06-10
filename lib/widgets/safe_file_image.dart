// lib/widgets/safe_file_image.dart
import 'dart:io';

import 'package:flutter/material.dart';

/// An [Image.file] that never throws when the underlying file is missing or
/// unreadable. If the file can't be loaded, [fallback] is shown instead of
/// letting a PathNotFoundException bubble up and break the widget tree.
class SafeFileImage extends StatelessWidget {
  const SafeFileImage({
    super.key,
    required this.path,
    this.fit,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fallback,
  });

  final String? path;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Widget? fallback;

  Widget _fallback(BuildContext context) {
    if (fallback != null) return fallback!;
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p == null || p.isEmpty || !File(p).existsSync()) {
      return _fallback(context);
    }
    return Image.file(
      File(p),
      fit: fit,
      width: width,
      height: height,
      color: color,
      colorBlendMode: colorBlendMode,
      errorBuilder: (context, error, stackTrace) => _fallback(context),
    );
  }
}
