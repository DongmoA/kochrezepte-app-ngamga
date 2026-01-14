// lib/models/recipe.dart

enum RecipeFilter {
  all,
  newest,
  popular,
  mine,
  favorite,
}

enum Difficulty { einfach, mittel, schwer }

class Recipe {
  final String? id;

  /// NEW: permet de savoir si la recette est à l’utilisateur courant
  /// (champ DB: owner_id)
  final String? ownerId;

  final String title;
  final String? imageUrl;
  final int durationMinutes;
  final int servings;
  final Difficulty difficulty;

  // ratings
  final double averageRating;
  final int totalRatings;

  // Nutrition
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  // relational lists
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final List<String> tags; // list of tag names

  // user who created the recipe
   final String? ownerName; 

  Recipe({
    this.id,
    this.ownerId,
    required this.title,
    this.imageUrl,
    required this.durationMinutes,
    required this.servings,
    required this.difficulty,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.ingredients = const [],
    this.steps = const [],
    this.tags = const [],
    this.ownerName,
  });

  /// Helper: gère nutrition renvoyé sous forme Map OU List<Map> (0..1)
  static Map<String, dynamic>? _extractNutrition(dynamic nutrition) {
    if (nutrition == null) return null;
    if (nutrition is Map<String, dynamic>) return nutrition;

    if (nutrition is List && nutrition.isNotEmpty) {
      final first = nutrition.first;
      if (first is Map<String, dynamic>) return first;
    }
    return null;
  }

  // Factory method to create a Recipe from JSON (as returned by Supabase)
  factory Recipe.fromJson(Map<String, dynamic> json) {
    final nutritionData = _extractNutrition(json['nutrition']);

    return Recipe(
      id: json['id']?.toString(),
      ownerId: json['owner_id']?.toString(), // NEW

      title: (json['title'] ?? '').toString(),
      imageUrl: json['image_url']?.toString(),
      ownerName: json['ownername']?.toString(), // NEW

      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      servings: (json['servings'] as num?)?.toInt() ?? 1,

      difficulty: _parseDifficulty(json['difficulty']?.toString()),

      calories: (nutritionData?['calories'] as num?)?.toInt(),
      protein: (nutritionData?['protein_g'] as num?)?.toDouble(),
      carbs: (nutritionData?['carbs_g'] as num?)?.toDouble(),
      fat: (nutritionData?['fat_g'] as num?)?.toDouble(),

      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (json['total_ratings'] as num?)?.toInt() ?? 0,

      ingredients: (json['recipe_ingredients'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => RecipeIngredient.fromJson(e))
              .toList() ??
          [],

      steps: (json['recipe_steps'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => RecipeStep.fromJson(e))
              .toList() ??
          [],

      tags: (json['recipe_tags'] as List<dynamic>?)
          ?.map((e) => e['tags']['name'] as String) 
          .toList() ?? [],
    );
  }

  // to send data back to Supabase
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'image_url': imageUrl,
      'duration_minutes': durationMinutes,
      'servings': servings,
      'difficulty': difficulty.name.capitalize(), // ex: "mittel" -> "Mittel"
      'average_rating': averageRating,
      'total_ratings': totalRatings,

      // owner_id: normalement set côté createRecipe via DatabaseService,
      // mais tu peux le laisser ici si tu veux faire un insert direct
      // 'owner_id': ownerId,
    };
  }

  static Difficulty _parseDifficulty(String? value) {
    switch (value?.toLowerCase()) {
      case 'einfach':
        return Difficulty.einfach;
      case 'schwer':
        return Difficulty.schwer;
      default:
        return Difficulty.mittel;
    }
  }
}

// Extension for String to capitalize the first letter
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class RecipeIngredient {
  final String name; // the name comes from the table 'ingredients'
  final double quantity;
  final String unit;

  RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    final ingObj = json['ingredients'];
    final String name = (ingObj is Map<String, dynamic>)
        ? (ingObj['name'] ?? 'Inconnu').toString()
        : (json['name'] ?? 'Inconnu').toString();

    return RecipeIngredient(
      name: name,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: (json['unit'] ?? '').toString(),
    );
  }
}

class RecipeStep {
  final int stepNumber;
  final String instruction;

  RecipeStep({required this.stepNumber, required this.instruction});

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      stepNumber: (json['step_number'] as num?)?.toInt() ?? 0,
      instruction: (json['instruction'] ?? '').toString(),
    );
  }
}
