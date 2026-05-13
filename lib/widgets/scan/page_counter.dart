// lib/widgets/scan/page_counter.dart
import 'package:flutter/material.dart';

/// Small pill showing "current / total" page numbers.
class PageCounter extends StatelessWidget {
  const PageCounter({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.45),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$current / $total',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
