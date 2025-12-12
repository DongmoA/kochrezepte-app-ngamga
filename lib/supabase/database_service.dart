import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';
import 'supabase_client.dart';
import 'auth_service.dart';

class DatabaseService {
  final SupabaseClient _db = SupabaseClientManager.client;
  final AuthService _authService = AuthService();

  /// Create a full recipe with ingredients, steps, tags and nutrition
  Future<String> createRecipe(Recipe recipe) async {
    try {
      // -----------------------------
      // 1. Insert recipe base data
      // -----------------------------
      final recipeRes = await _db
          .from('recipes')
          .insert({
            'title': recipe.title,
            'image_url': recipe.imageUrl,
            'duration_minutes': recipe.durationMinutes,
            'servings': recipe.servings,
            'difficulty': recipe.difficulty.name[0].toUpperCase() + recipe.difficulty.name.substring(1),          })
          .select()
          .single();

      final recipeId = recipeRes['id'] as String;

      // -----------------------------
      // 2. Insert nutrition data
      // -----------------------------
      if (recipe.calories != null ||
          recipe.protein != null ||
          recipe.carbs != null ||
          recipe.fat != null) {
        await _db.from('nutrition').insert({
          'recipe_id': recipeId,
          'calories': recipe.calories,
          'protein_g': recipe.protein,
          'carbs_g': recipe.carbs,
          'fat_g': recipe.fat,
        });
      }

      // -----------------------------
      // 3. Insert steps
      // -----------------------------
      for (final step in recipe.steps) {
        await _db.from('recipe_steps').insert({
          'recipe_id': recipeId,
          'step_number': step.stepNumber,
          'instruction': step.instruction,
        });
      }

      // -----------------------------
      // 4. Insert ingredients
      // -----------------------------
      for (final ing in recipe.ingredients) {
        // Check if ingredient already exists by name
        final existingIng = await _db
            .from('ingredients')
            .select()
            .eq('name', ing.name)
            .maybeSingle();

        String ingredientId;

        if (existingIng == null) {
          // Create ingredient if not found
          final newIng = await _db
              .from('ingredients')
              .insert({'name': ing.name})
              .select()
              .single();
          ingredientId = newIng['id'] as String;
        } else {
          ingredientId = existingIng['id'] as String;
        }

        // Insert recipe-ingredient relation
        await _db.from('recipe_ingredients').insert({
          'recipe_id': recipeId,
          'ingredient_id': ingredientId,
          'quantity': ing.quantity,
          'unit': ing.unit,
        });
      }

      // -----------------------------
      // 5. Insert tags
      // -----------------------------
      for (final tagName in recipe.tags) {
        // Check if tag already exists
        final tag = await _db
            .from('tags')
            .select()
            .eq('name', tagName)
            .maybeSingle();

        String tagId;

        if (tag == null) {
          // Create tag if needed
          final newTag = await _db
              .from('tags')
              .insert({'name': tagName})
              .select()
              .single();
          tagId = newTag['id'];
        } else {
          tagId = tag['id'];
        }

        // Insert recipe-tag relation
        await _db.from('recipe_tags').insert({
          'recipe_id': recipeId,
          'tag_id': tagId,
        });
      }

      return recipeId; // Success

    } catch (e) {
      debugPrint(" ERROR createRecipe(): $e");
      rethrow;
    }
  }
  
  Future<List<Recipe>> fetchAllRecipes() async {
    try {
      final List<Map<String, dynamic>>  data = await _db
          .from('recipes')
          .select('''
            *,
            recipe_ingredients(
              *,
              ingredients(*)
            ),
            recipe_steps(*),
            recipe_tags(
              *,
              tags(*)
            ),
            nutrition(*)
          ''');
      
      final recipes = data
          .map((json) => Recipe.fromJson(json))
          .toList();
      
      return recipes;
    } catch (e) {
      debugPrint(" ERROR fetchAllRecipes(): $e");
      return [];
    }
  }

/// Retrieves the score given by the current user for a specific recipe.
  /// Returns the score (int) or null if the user has not yet rated it.
  Future<int?> fetchUserRating(String recipeId) async {
    // Get the current user's ID using the helper from AuthService
    final userId = _authService.getCurrentUserId();

  
    try {
      final Map<String, dynamic>? data = await _db
          .from('ratings')
          .select('score')
          .eq('recipe_id', recipeId)
          .eq('user_id', userId) // KEY: Selects the rating from THIS specific user
          .maybeSingle(); // Returns one result or null

      if (data != null && data.containsKey('score')) {
        return data['score'] as int;
      }
      return null;
      
    } catch (e) {
      debugPrint("ERROR fetchUserRating(): $e");
      return null;
    }
  }


  /// Adds/Modifies a user's rating, then updates the recipe's aggregated cache.
  Future<void> rateRecipe({
    required String recipeId, 
    required int score
  }) async {
    try {
      // Use the helper to ensure the user is logged in
      final userId = _authService.getCurrentUserId(); 

      // 1. Insert or Update the rating in the 'ratings' table (ensures 1 vote per user via upsert)
      await _db.from('ratings').upsert({
        'recipe_id': recipeId,
        'user_id': userId,
        'score': score,
      });

      // 2. Calculate the new average and total (requires reading all ratings for this recipe)
      final List<Map<String, dynamic>> ratingsData = await _db
          .from('ratings')
          .select('score')
          .eq('recipe_id', recipeId);

      if (ratingsData.isEmpty) return; // Should not happen after the upsert

      double totalScore = 0;
      for (var row in ratingsData) {
        totalScore += (row['score'] as num).toDouble();
      }
      
      final int newTotalRatings = ratingsData.length;
      // Calculate the new average and fix it to one decimal place for storage
      final double newAverage = double.parse((totalScore / newTotalRatings).toStringAsFixed(1));

      // 3. Update the 'recipes' table (the cache) with the new aggregated values
      await _db.from('recipes').update({
        'average_rating': newAverage,
        'total_ratings': newTotalRatings,
      }).eq('id', recipeId);

      debugPrint("Rating successful. New average: $newAverage ($newTotalRatings votes)");

    } catch (e) {
      debugPrint("ERROR rateRecipe(): $e");
      rethrow;
    }
  }

}
