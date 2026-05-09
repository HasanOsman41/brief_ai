// lib/utils/risk_level.dart
import 'package:brief_ai/theme/app_theme.dart';
import 'package:flutter/material.dart';

enum RiskLevel {
  overdue('overdue', AppTheme.lightDanger, AppTheme.darkDanger, Icons.error),
  wichtig('taskWichtig', AppTheme.lightDanger, AppTheme.darkDanger, Icons.warning),
  pruefen('taskPruefen', AppTheme.lightWarning, AppTheme.darkWarning, Icons.schedule),
  offen('taskOffen', AppTheme.lightSuccess, AppTheme.darkSuccess, Icons.check_circle);

  final String translationKey;
  final Color lightColor;
  final Color darkColor;
  final IconData icon;

  const RiskLevel(this.translationKey, this.lightColor, this.darkColor, this.icon);

  Color color(bool isDark) => isDark ? darkColor : lightColor;
}

RiskLevel calcRiskLevel(DateTime? deadline) {
  if (deadline == null) return RiskLevel.offen;
  final hours = deadline.difference(DateTime.now()).inHours;
  if (hours < 0) return RiskLevel.overdue;
  if (hours <= 24) return RiskLevel.wichtig;
  if (deadline.difference(DateTime.now()).inDays <= 3) return RiskLevel.pruefen;
  return RiskLevel.offen;
}
