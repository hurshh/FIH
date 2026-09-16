import 'package:flutter/material.dart';

const ink = Color(0xFF243F38);
const muted = Color(0xFF63736A);
const cream = Color(0xFFFAF9F3);
const forest = Color(0xFF28664F);
const mint = Color(0xFFE9F0E4);
const ocean = Color(0xFFE6F1EE);
const line = Color(0xFFE2E6DC);
const coral = Color(0xFFE59173);
const countryColors = [
  Color(0xFFC7DCAF),
  Color(0xFFF0D997),
  Color(0xFFE8B6A0),
  Color(0xFFA6CFBF),
  Color(0xFFD2C8D9),
  Color(0xFFD6D59E),
];

TextStyle displayStyle(double size) => TextStyle(
  fontFamily: 'Fraunces',
  fontSize: size,
  height: 1.14,
  fontWeight: FontWeight.w600,
  color: ink,
  letterSpacing: -0.8,
);

ThemeData atlasTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: cream,
  fontFamily: 'Nunito',
  colorScheme: ColorScheme.fromSeed(seedColor: forest, surface: cream),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: ink, fontSize: 15, height: 1.5),
    bodyLarge: TextStyle(color: ink, fontSize: 17, height: 1.5),
    titleMedium: TextStyle(
      color: ink,
      fontSize: 17,
      fontWeight: FontWeight.w800,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: forest,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      textStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ink,
      minimumSize: const Size(48, 48),
      side: const BorderSide(color: line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: ink,
      minimumSize: const Size(48, 48),
    ),
  ),
  dividerColor: line,
);
