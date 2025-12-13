import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';
import 'supabase_client.dart';
import 'auth_service.dart';

class DatabaseService {
  final SupabaseClient _db = SupabaseClientManager.client;
  final AuthService _authService = AuthService();

  // ==================== CREATE RECIPE ====================
  Future<String> createRecipe(Recipe recipe) async {
    try {
      final userId = _db.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // 1. Insert recipe base data
      final recipeRes = await _db
          .from('recipes')
          .insert({
            'title': recipe.title,
            'image_url': recipe.imageUrl,
            'duration_minutes': recipe.durationMinutes,
            'servings': recipe.servings,
            'difficulty': recipe.difficulty.name[0].toUpperCase() + recipe.difficulty.name.substring(1),
            'author_id': userId,
          })
          .select()
          .single();

      final recipeId = recipeRes['id'] as String;

      // 2. Insert nutrition data
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

      // 3. Insert steps
      for (final step in recipe.steps) {
        await _db.from('recipe_steps').insert({
          'recipe_id': recipeId,
          'step_number': step.stepNumber,
          'instruction': step.instruction,
        });
      }

      // 4. Insert ingredients
      for (final ing in recipe.ingredients) {
        final existingIng = await _db
            .from('ingredients')
            .select()
            .eq('name', ing.name)
            .maybeSingle();

        String ingredientId;

        if (existingIng == null) {
          final newIng = await _db
              .from('ingredients')
              .insert({'name': ing.name})
              .select()
              .single();
          ingredientId = newIng['id'] as String;
        } else {
          ingredientId = existingIng['id'] as String;
        }

        await _db.from('recipe_ingredients').insert({
          'recipe_id': recipeId,
          'ingredient_id': ingredientId,
          'quantity': ing.quantity,
          'unit': ing.unit,
        });
      }

      // 5. Insert tags
      for (final tagName in recipe.tags) {
        final tag = await _db
            .from('tags')
            .select()
            .eq('name', tagName)
            .maybeSingle();

        String tagId;

        if (tag == null) {
          final newTag = await _db
              .from('tags')
              .insert({'name': tagName})
              .select()
              .single();
          tagId = newTag['id'];
        } else {
          tagId = tag['id'];
        }

        await _db.from('recipe_tags').insert({
          'recipe_id': recipeId,
          'tag_id': tagId,
        });
      }

      return recipeId;

    } catch (e) {
      debugPrint("❌ ERROR createRecipe(): $e");
      rethrow;
    }
  }

  // ==================== FETCH RECIPES ====================
  
  /// Fetch ALL recipes (for general listing)
  Future<List<Recipe>> fetchAllRecipes() async {
    try {
      final data = await _db
          .from('recipes')
          .select('''
            *,
            recipe_ingredients(quantity, unit, ingredients(name)),
            recipe_steps(step_number, instruction),
            recipe_tags(tags(name)),
            nutrition(calories, protein_g, carbs_g, fat_g)
          ''')
          .order('created_at', ascending: false);
      
      return _parseRecipes(data);
    } catch (e) {
      debugPrint("❌ ERROR fetchAllRecipes(): $e");
      return [];
    }
  }

  /// Tab 1: MEINE REZEPTE - Recipes created by current user
  Future<List<Recipe>> fetchMyRecipes() async {
    try {
      final userId = _db.auth.currentUser?.id;
      
      if (userId == null) {
        debugPrint("⚠️ No user logged in");
        return [];
      }

      final data = await _db
          .from('recipes')
          .select('''
            *,
            recipe_ingredients(quantity, unit, ingredients(name)),
            recipe_steps(step_number, instruction),
            recipe_tags(tags(name)),
            nutrition(calories, protein_g, carbs_g, fat_g)
          ''')
          .eq('author_id', userId)
          .order('created_at', ascending: false);
      
      debugPrint("✅ ${(data as List).length} own recipes loaded");
      return _parseRecipes(data);
    } catch (e) {
      debugPrint("❌ ERROR fetchMyRecipes(): $e");
      return [];
    }
  }

  /// Tab 2: GESPEICHERTE REZEPTE - User's saved/favorited recipes
  Future<List<Recipe>> fetchSavedRecipes() async {
    try {
      final userId = _db.auth.currentUser?.id;
      
      if (userId == null) {
        debugPrint("⚠️ No user logged in");
        return [];
      }

      // Get recipe IDs from user_favorites
      final favoritesData = await _db
          .from('user_favorites')
          .select('recipe_id')
          .eq('user_id', userId);

      if (favoritesData.isEmpty) {
        return [];
      }

      final recipeIds = (favoritesData as List)
          .map((e) => e['recipe_id'] as String)
          .toList();

      // Fetch full recipe data
      final data = await _db
          .from('recipes')
          .select('''
            *,
            recipe_ingredients(quantity, unit, ingredients(name)),
            recipe_steps(step_number, instruction),
            recipe_tags(tags(name)),
            nutrition(calories, protein_g, carbs_g, fat_g)
          ''')
          .inFilter('id', recipeIds)
          .order('created_at', ascending: false);
      
      debugPrint("✅ ${(data as List).length} saved recipes loaded");
      return _parseRecipes(data);
    } catch (e) {
      debugPrint("❌ ERROR fetchSavedRecipes(): $e");
      return [];
    }
  }

  /// Tab 3: BELIEBTE REZEPTE - Popular recipes based on high ratings
  Future<List<Recipe>> fetchPopularRecipes() async {
    try {
      final data = await _db
          .from('recipes')
          .select('''
            *,
            recipe_ingredients(quantity, unit, ingredients(name)),
            recipe_steps(step_number, instruction),
            recipe_tags(tags(name)),
            nutrition(calories, protein_g, carbs_g, fat_g)
          ''')
          .gte('average_rating', 3.5) // ← Für Testing: 3.5 statt 4.0
          .gte('total_ratings', 1) // ← Für Testing: 1 statt 5
          .order('average_rating', ascending: false)
          .limit(20);
      
      debugPrint("✅ ${(data as List).length} popular recipes loaded");
      return _parseRecipes(data);
    } catch (e) {
      debugPrint("❌ ERROR fetchPopularRecipes(): $e");
      return [];
    }
  }

  /// Tab 4: NEUE REZEPTE - Recently created recipes (last 3 days)
  Future<List<Recipe>> fetchNewRecipes() async {
    try {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      
      final data = await _db
          .from('recipes')
          .select('''
            *,
            recipe_ingredients(quantity, unit, ingredients(name)),
            recipe_steps(step_number, instruction),
            recipe_tags(tags(name)),
            nutrition(calories, protein_g, carbs_g, fat_g)
          ''')
          .gte('created_at', threeDaysAgo.toIso8601String())
          .order('created_at', ascending: false)
          .limit(50);
      
      debugPrint("✅ ${(data as List).length} new recipes loaded");
      return _parseRecipes(data);
    } catch (e) {
      debugPrint("❌ ERROR fetchNewRecipes(): $e");
      return [];
    }
  }

  // ==================== FAVORITES MANAGEMENT ====================
  
  /// Add recipe to favorites
  Future<void> addToFavorites(String recipeId) async {
    try {
      final userId = _db.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await _db.from('user_favorites').insert({
        'user_id': userId,
        'recipe_id': recipeId,
      });
      
      debugPrint("✅ Recipe added to favorites");
    } catch (e) {
      debugPrint("❌ ERROR addToFavorites(): $e");
      rethrow;
    }
  }

  /// Remove recipe from favorites
  Future<void> removeFromFavorites(String recipeId) async {
    try {
      final userId = _db.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await _db
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId);
      
      debugPrint("✅ Recipe removed from favorites");
    } catch (e) {
      debugPrint("❌ ERROR removeFromFavorites(): $e");
      rethrow;
    }
  }

  /// Check if recipe is in favorites
  Future<bool> isFavorite(String recipeId) async {
    try {
      final userId = _db.auth.currentUser?.id;
      
      if (userId == null) {
        return false;
      }

      final data = await _db
          .from('user_favorites')
          .select()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId)
          .maybeSingle();
      
      return data != null;
    } catch (e) {
      debugPrint("❌ ERROR isFavorite(): $e");
      return false;
    }
  }

  // ==================== RATING SYSTEM ====================
  
  /// Retrieves the score given by the current user for a specific recipe.
  /// Returns the score (int) or null if the user has not yet rated it.
  Future<int?> fetchUserRating(String recipeId) async {
    final userId = _authService.getCurrentUserId();
    
    try {
      final Map<String, dynamic>? data = await _db
          .from('ratings')
          .select('score')
          .eq('recipe_id', recipeId)
          .eq('user_id', userId)
          .maybeSingle();

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
      final userId = _authService.getCurrentUserId(); 

      // 1. Insert or Update the rating
      await _db.from('ratings').upsert({
        'recipe_id': recipeId,
        'user_id': userId,
        'score': score,
      });

      // 2. Calculate the new average and total
      final List<Map<String, dynamic>> ratingsData = await _db
          .from('ratings')
          .select('score')
          .eq('recipe_id', recipeId);

      if (ratingsData.isEmpty) return;

      double totalScore = 0;
      for (var row in ratingsData) {
        totalScore += (row['score'] as num).toDouble();
      }
      
      final int newTotalRatings = ratingsData.length;
      final double newAverage = double.parse((totalScore / newTotalRatings).toStringAsFixed(1));

      // 3. Update the recipes table
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

  // ==================== HELPER METHODS ====================
  
  List<Recipe> _parseRecipes(dynamic data) {
    try {
      return (data as List<dynamic>)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("❌ ERROR parsing recipes: $e");
      return [];
    }
  }
}