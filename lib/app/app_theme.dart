import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
    useMaterial3: true,
  );

  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(centerTitle: false),
    cardTheme: const CardThemeData(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}
