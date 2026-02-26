// lib/widgets/scan/scan_gallery.dart
import 'dart:io';

import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Full-screen grid gallery of all scanned pages.
class ScanGallery extends StatelessWidget {
  const ScanGallery({
    super.key,
    required this.imagePaths,
    required this.selectedIndex,
    required this.onSelect,
    required this.onDelete,
    required this.onClose,
  });

  final List<String> imagePaths;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(children: [
            Expanded(
              child: Text(
                AppLocalizations.tr(context, 'galleryCount').replaceAll('%d', imagePaths.length.toString()),
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
              onPressed: onClose,
            ),
          ]),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6,
            ),
            itemCount: imagePaths.length,
            itemBuilder: (_, i) => _GalleryTile(
              path: imagePaths[i],
              pageNumber: i + 1,
              isSelected: i == selectedIndex,
              primary: primary,
              isDark: isDark,
              onTap: () => onSelect(i),
              onDelete: () => onDelete(i),
            ),
          ),
        ),
      ]),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.path,
    required this.pageNumber,
    required this.isSelected,
    required this.primary,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  final String path;
  final int pageNumber;
  final bool isSelected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(fit: StackFit.expand, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? primary : Colors.transparent, width: 3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          bottom: 6, left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
            child: Text('$pageNumber', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ),
        Positioned(
          top: 6, right: 6,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: isDark ? AppTheme.darkDanger : AppTheme.lightDanger, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ]),
    );
  }
}
