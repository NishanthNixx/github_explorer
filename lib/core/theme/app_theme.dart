import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color _seed = Color(0xFF24292F);

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seed),
    useMaterial3: true,
  );
}
