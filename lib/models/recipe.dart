
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
  final String title;
  final String? imageUrl;
  final int durationMinutes;
  final int servings;
  final Difficulty difficulty;

  // raitings
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
   final String? ownerEmail; 

  Recipe({
    this.id,
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
    this.ownerEmail,
  });

  // Factory method to create a Recipe from JSON (as returned by Supabase)
  factory Recipe.fromJson(Map<String, dynamic> json) {
  
  final nutritionData = json['nutrition'] as Map<String, dynamic>?;

    return Recipe(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'],
      durationMinutes: json['duration_minutes'] ?? 0,
      servings: json['servings'] ?? 1,
      difficulty: _parseDifficulty(json['difficulty']),
      calories: nutritionData?['calories'] ,
      protein: (nutritionData?['protein_g'] as num?)?.toDouble(),
      carbs: (nutritionData?['carbs_g'] as num?)?.toDouble(),
      fat: (nutritionData?['fat_g'] as num?)?.toDouble(),
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['total_ratings'] ?? 0,
      // relational data (assuming Supabase returns nested data like
      // select(*, recipe_ingredients(...)))
      ingredients: (json['recipe_ingredients'] as List<dynamic>?)
          ?.map((e) => RecipeIngredient.fromJson(e))
          .toList() ?? [],
          
      steps: (json['recipe_steps'] as List<dynamic>?)
          ?.map((e) => RecipeStep.fromJson(e))
          .toList() ?? [],
          
      tags: (json['recipe_tags'] as List<dynamic>?)
          ?.map((e) => e['tags']['name'] as String) 
          .toList() ?? [],
      ownerEmail: json['owner_email'] as String?,  
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
    };
  }

  static Difficulty _parseDifficulty(String? value) {
    switch (value?.toLowerCase()) {
      case 'einfach': return Difficulty.einfach;
      case 'schwer': return Difficulty.schwer;
      default: return Difficulty.mittel;
    }
  }
}

// Extension for String to capitalize the first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class RecipeIngredient {
  final String name; // the name come from the table 'ingredients'
  final double quantity;
  final String unit;

  RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      // Gère le cas où Supabase renvoie l'objet ingredient imbriqué
      name: json['ingredients'] != null ? json['ingredients']['name'] : 'Inconnu',
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
    );
  }
}

class RecipeStep {
  final int stepNumber;
  final String instruction;

  RecipeStep({required this.stepNumber, required this.instruction});

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      stepNumber: json['step_number'],
      instruction: json['instruction'],
    );
  }
}