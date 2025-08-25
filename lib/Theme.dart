import 'package:flutter/material.dart';
import 'package:v60pal/models/Recipe.dart';


final PRIMARY_COLOR = Colors.blueAccent;

final SECONDARY_COLOR = Colors.lightBlue;

final BACKGROUND_COLOR = Colors.black;

final BUTTON_COLOR = Colors.white10;

final TEXT_COLOR = Colors.white;

final COLOR_SCHEME = ColorScheme(brightness: Brightness.dark, primary: PRIMARY_COLOR, onPrimary: TEXT_COLOR, secondary: SECONDARY_COLOR, onSecondary: TEXT_COLOR, error: TEXT_COLOR, onError: BACKGROUND_COLOR, surface: BACKGROUND_COLOR, onSurface: TEXT_COLOR);

final ELEVATED_BUTTON_THEME = ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: BUTTON_COLOR));

final MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

final List<Recipe> RECIPES = [
    Recipe(
      id: '0',
      name: "4:6 Method",
      waterWeightGrams: 300,
      waterTemp: 45,
      pourSteps: [45, 90, 135, 180, 225],
      coffeeDose: "20g",
      grindSize: "fine",
      brewTime: "1:50",
      pourAmounts: [60, 120, 180, 240, 300],
    ),
    Recipe(
      id: '1',
      name: "James Hoffmann",
      waterWeightGrams: 250,
      waterTemp: 45,
      pourSteps: [45, 70, 90, 110, 180],
      coffeeDose: "15g",
      grindSize: "medium-fine",
      brewTime: "3:00",
      pourAmounts: [50, 100, 150, 200, 250],
    ),
    Recipe(
      id: '2',
      name: "Scott Rao",
      waterWeightGrams: 340,
      waterTemp: 45,
      pourSteps: [60, 120, 180],
      coffeeDose: "20g",
      grindSize: "medium-fine",
      brewTime: "1:50",
      pourAmounts: [60, 210, 340],
    ),
    Recipe(
      id: '3',
      name: "4:6",
      waterWeightGrams: 225,
      waterTemp: 45,
      pourSteps: [45, 45, 45, 45, 45],
      coffeeDose: "15g",
      grindSize: "fine",
      brewTime: "1:50",
      pourAmounts: [45, 45, 45, 45, 45],
    ),
    Recipe(
      id: '4',
      name: "4:6",
      waterWeightGrams: 225,
      waterTemp: 45,
      pourSteps: [45, 45, 45, 45, 45],
      coffeeDose: "15g",
      grindSize: "fine",
      brewTime: "1:50",
      pourAmounts: [45, 45, 45, 45, 45],
    ),
    Recipe(
      id: '5',
      name: "Onyx Method",
      waterWeightGrams: 250,
      waterTemp: 30,
      pourSteps: [30, 90, 150],
      coffeeDose: "15g",
      grindSize: "medium-fine",
      brewTime: "2:30",
      pourAmounts: [50, 150, 250],
    ),
    Recipe(
      id: '6',
      name: "4:6",
      waterWeightGrams: 225,
      waterTemp: 45,
      pourSteps: [45, 45, 45, 45, 45],
      coffeeDose: "15g",
      grindSize: "fine",
      brewTime: "1:50",
      pourAmounts: [45, 45, 45, 45, 45],
    ),
  ];