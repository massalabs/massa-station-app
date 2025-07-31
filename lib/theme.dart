import 'package:flutter/material.dart';

final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: Colors.blueGrey[800]!,
    onPrimary: Colors.white,
    surface: Colors.grey[900]!,
    onSurface: Colors.white70,
  ),
  scaffoldBackgroundColor: Colors.black,
  cardColor: Colors.grey[850],
  textTheme: const TextTheme(
    headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    bodyMedium: TextStyle(color: Colors.white70),
    bodySmall: TextStyle(color: Colors.white54),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[800],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(color: Colors.white12),
    ),
    hintStyle: const TextStyle(color: Colors.white38),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueGrey[700],
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
);

final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: Colors.blueGrey[600]!,
    onPrimary: Colors.white,
    surface: Colors.grey[100]!,
    onSurface: Colors.black87,
  ),
  scaffoldBackgroundColor: Colors.white,
  cardColor: Colors.grey[100],
  textTheme: const TextTheme(
    headlineSmall: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    bodyMedium: TextStyle(color: Colors.black87),
    bodySmall: TextStyle(color: Colors.black54),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[200],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(color: Colors.black12),
    ),
    hintStyle: const TextStyle(color: Colors.black38),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueGrey[800],
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
);
