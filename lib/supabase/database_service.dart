import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipe.dart';
import 'supabase_client.dart';
import 'auth_service.dart';

class DatabaseService {
  final SupabaseClient _db = SupabaseClientManager.client;
  final AuthService _authService = AuthService();
   String get userId => _authService.getCurrentUserId(); 

  /// Create a full recipe with ingredients, steps, tags and nutrition
  Future<String> createRecipe(Recipe recipe) async {
    try {
     
      // 1. Insert recipe base data
   
      final recipeRes = await _db
          .from('recipes')
          .insert({
            'title': recipe.title,
            'image_url': recipe.imageUrl,
            'duration_minutes': recipe.durationMinutes,
            'servings': recipe.servings,
            'difficulty': recipe.difficulty.name[0].toUpperCase() + recipe.difficulty.name.substring(1),       
            'owner_id': userId,
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

     
      // 5. Insert tags
    
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

  /// Toggles the favorite status of a recipe for the current user.
  Future<void> toggleFavorite(String recipeId) async {

    try {
      // Check if it already exists
      final existing = await _db
          .from('user_favorites')
          .select()
          .eq('user_id', userId)
          .eq('recipe_id', recipeId)
          .maybeSingle();

      if (existing != null) {
        // Remove from favorites
        await _db
            .from('user_favorites')
            .delete()
            .eq('id', existing['id']);
      } else {
        // Add to favorites
        await _db.from('user_favorites').insert({
          'user_id': userId,
          'recipe_id': recipeId,
        });
      }
    } catch (e) {
      debugPrint("ERROR toggleFavorite: $e");
      rethrow; // Let the UI know something went wrong
    }
  }

  /// Retrieves the list of favorite recipe IDs for the current user.
  Future<Set<String>> fetchUserFavorites() async {
    if (userId.isEmpty) return {};

    try {
      final response = await _db
          .from('user_favorites')
          .select('recipe_id')
          .eq('user_id', userId);

      return (response as List)
          .map((item) => item['recipe_id'] as String)
          .toSet();
    } catch (e) {
      debugPrint("ERROR fetchUserFavorites(): $e");
      return {};
    }
  }
  
  Future<List<Recipe>> fetchAllRecipes({required RecipeFilter filter}) async {
   if (userId.isEmpty)   return []; // No user logged in
   _authService.getCurrentUserId(); 

    const String selectQuery = '''
      *,
      nutrition(*),
      recipe_ingredients(*, ingredients(*)),
      recipe_steps(*),
      recipe_tags(*, tags(*))
    ''';
 
    try {
     List<dynamic> data;

     // Apply filter conditions
     // first special case : favorite recipes
     if (filter ==  RecipeFilter.favorite) {
     
      final response = await _db
            .from('user_favorites')
            .select('recipes_with_owner($selectQuery)') // Nested select to get full recipe data
            .eq('user_id', userId)
            .order('created_at', ascending: false); // Newest first
      data = response.map((e) => e['recipes_with_owner']).toList();
      data.removeWhere((element) => element == null); // Clean nulls
     } else {
      // other filters 
        dynamic query = _db.from('recipes_with_owner').select(selectQuery);

        switch (filter) {
          case RecipeFilter.mine:
           
            query = query.eq('owner_id', userId); // Filter by current user's recipes
            query = query.order('created_at', ascending: false);
            break;

          case RecipeFilter.newest:
            // 'new' filter : order by creation date descending
            query = query.order('created_at', ascending: false);
            break;

          case RecipeFilter.popular:
            // 'popular' filter : order by average_rating desc, then total_ratings desc
            query = query.order('average_rating', ascending: false);
            query = query.order('total_ratings', ascending: false);
            break;

          case RecipeFilter.all:
          default:
            // 'all' filter : order by title ascending
            query = query.order('title', ascending: true);
            break;
        }
        
        data = await query;
      }

      // Conversion JSON -> Objets Recipe
      return data.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint(" ERROR fetchAllRecipes(): $e");
      return [];
    }
  }

/// Retrieves the score given by the current user for a specific recipe.
  /// Returns the score (int) or null if the user has not yet rated it.
  Future<int?> fetchUserRating(String recipeId) async {
    // Get the current user's ID using the helper from AuthService
   // final userId = _authService.getCurrentUserId();

  
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



// method to fetch all ratings for a recipe along with user info
Future<List<Map<String, dynamic>>> fetchAllRatingsForRecipe(String recipeId) async {
  try {
    final data = await _db
        .from('ratings_with_users') 
        .select('score, comment, created_at, user_email')
        .eq('recipe_id', recipeId)
        .order('created_at', ascending: false);

    return (data as List).map((rating) {
      return {
        'score': rating['score'],
        'comment': rating['comment'],
        'created_at': rating['created_at'],
        'user_name': rating['user_email'] ?? 'Anonymous', 
      };
    }).toList();
  } catch (e) {
    debugPrint('ERROR fetchAllRatingsForRecipe(): $e');
    rethrow;
  }
}

// method to rate a recipe
Future<Map<String, dynamic>> rateRecipe({
  required String recipeId, 
  required int score,
  String? comment,
}) async {
  try {
    // Insert new rating
    await _db.from('ratings').insert({
      'recipe_id': recipeId,
      'user_id': userId,
      'score': score,
      'comment': comment,
    });

    // Recalculate average rating and total ratings
    final List<Map<String, dynamic>> ratingsData = await _db
        .from('ratings')
        .select('score')
        .eq('recipe_id', recipeId);

    double totalScore = 0;
    for (var row in ratingsData) {
      totalScore += (row['score'] as num).toDouble();
    }
    
    final int newTotalRatings = ratingsData.length;
    final double newAverage = double.parse(
      (totalScore / newTotalRatings).toStringAsFixed(1)
    );

    // Update recipe with new stats
    await _db.from('recipes').update({
      'average_rating': newAverage,
      'total_ratings': newTotalRatings,
    }).eq('id', recipeId);

    return {'average': newAverage, 'total': newTotalRatings};
  } catch (e) {
    debugPrint("ERROR rateRecipe(): $e");
    rethrow;
  }
}

/// Fetches the average rating and total ratings for a given recipe.
Future<Map<String, num>> fetchRecipeStats(String recipeId) async {
  try {
    final data = await _db
        .from('recipes')
        .select('average_rating, total_ratings')
        .eq('id', recipeId)
        .single();
    
    return {
      'average': (data['average_rating'] as num?) ?? 0.0,
      'total': (data['total_ratings'] as num?) ?? 0,
    };
  } catch (e) {
    debugPrint('ERROR fetchRecipeStats(): $e');
    return {'average': 0.0, 'total': 0};
  }
}

}
