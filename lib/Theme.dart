import 'package:flutter/material.dart';


final PRIMARY_COLOR = Colors.blueAccent;

final SECONDARY_COLOR = Colors.lightBlue;

final BACKGROUND_COLOR = Colors.black;

final BUTTON_COLOR = Colors.white10;

final TEXT_COLOR = Colors.white;

final COLOR_SCHEME = ColorScheme(brightness: Brightness.dark, primary: PRIMARY_COLOR, onPrimary: TEXT_COLOR, secondary: SECONDARY_COLOR, onSecondary: TEXT_COLOR, error: TEXT_COLOR, onError: BACKGROUND_COLOR, surface: BACKGROUND_COLOR, onSurface: TEXT_COLOR);

final ELEVATED_BUTTON_THEME = ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: BUTTON_COLOR));