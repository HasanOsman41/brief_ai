// lib/widgets/backup_item_tile.dart
import 'package:flutter/material.dart';

class BackupItemTile extends StatelessWidget {
  const BackupItemTile({
    Key? key,
    required this.name,
    required this.date,
    required this.size,
    required this.onRestorePressed,
  }) : super(key: key);

  final String name;
  final String date;
  final String size;
  final VoidCallback onRestorePressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(
        '$date • $size',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.restore),
        onPressed: onRestorePressed,
        color: Theme.of(context).colorScheme.primary,
        iconSize: 24,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
