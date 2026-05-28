import 'package:v60pal/models/Recipe.dart';

class BrewGuardrails {
  static const int minPlausibleWaterTempC = 75;
  static const int maxPlausibleWaterTempC = 100;

  static bool isPlausibleWaterTemp(int? tempC) {
    return tempC != null &&
        tempC >= minPlausibleWaterTempC &&
        tempC <= maxPlausibleWaterTempC;
  }

  static int? parseWaterTemp(String value) {
    final parsed = int.tryParse(value.trim());
    return isPlausibleWaterTemp(parsed) ? parsed : null;
  }

  static int? positiveSeconds(int? seconds) {
    return seconds != null && seconds > 0 ? seconds : null;
  }

  static List<String> recipeWarnings(Recipe recipe) {
    final warnings = <String>[];
    if (!isPlausibleWaterTemp(recipe.waterTemp)) {
      warnings.add(
        'Water temp ${recipe.waterTemp} C is unusual for V60. Confirm before logging.',
      );
    }
    if (recipe.waterWeightGrams <= 0) {
      warnings.add('Water amount is missing.');
    }
    if (recipe.pourSteps.isEmpty || recipe.pourSteps.last <= 0) {
      warnings.add('Brew time is missing.');
    }
    return warnings;
  }
}
