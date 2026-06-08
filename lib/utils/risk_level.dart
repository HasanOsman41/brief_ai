// lib/utils/risk_level.dart
import 'package:brief_ai/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum RiskLevel {
  overdue('overdue', AppTheme.lightDanger, AppTheme.darkDanger, Icons.error),
  wichtig(
    'taskWichtig',
    AppTheme.lightDanger,
    AppTheme.darkDanger,
    Icons.warning,
  ),
  pruefen(
    'taskPruefen',
    AppTheme.lightWarning,
    AppTheme.darkWarning,
    Icons.schedule,
  ),
  offen(
    'taskOffen',
    AppTheme.lightSuccess,
    AppTheme.darkSuccess,
    Icons.check_circle,
  );

  final String translationKey;
  final Color lightColor;
  final Color darkColor;
  final IconData icon;

  const RiskLevel(
    this.translationKey,
    this.lightColor,
    this.darkColor,
    this.icon,
  );

  Color color(bool isDark) => isDark ? darkColor : lightColor;
}

(RiskLevel, Color) calcRiskLevel(DateTime? deadline, bool isDark) {
  final RiskLevel level;
  if (deadline == null) {
    level = RiskLevel.offen;
  } else {
    final hours = deadline.difference(DateTime.now()).inHours;
    if (hours < 0) {
      level = RiskLevel.overdue;
    } else if (hours <= 48) {
      level = RiskLevel.wichtig;
    } else if (deadline.difference(DateTime.now()).inDays <= 4) {
      level = RiskLevel.pruefen;
    } else {
      level = RiskLevel.offen;
    }
  }
  return (level, level.color(isDark));
}
