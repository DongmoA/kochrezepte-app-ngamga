import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';
import 'supabase_client.dart';

class DatabaseService {
  final SupabaseClient _db = SupabaseClientManager.client;

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
      final data = await _db
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
      
      final recipes = (data as List<dynamic>)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
      
      return recipes;
    } catch (e) {
      debugPrint(" ERROR fetchAllRecipes(): $e");
      return [];
    }
  }

}
