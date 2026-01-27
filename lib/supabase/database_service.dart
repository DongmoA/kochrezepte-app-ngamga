// lib/supabase/database_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/recipe.dart';
import 'auth_service.dart';
import 'supabase_client.dart';

class DatabaseService {
  final SupabaseClient _db = SupabaseClientManager.client;
  final AuthService _authService = AuthService();

  String get userId => _authService.getCurrentUserId();

  // Helper: convertit n'importe quel id Supabase (int/uuid) en String
  String _id(dynamic value) => value?.toString() ?? '';
  // Ernährungspräferenz des Benutzers abrufen
  Future<String?> getUserDietPreference() async {
    try {
      final result = await _db
          .from('profiles')
          .select('diet_preference')
          .eq('id', userId)
          .maybeSingle();
      
      return result?['diet_preference'] as String?;
    } catch (e) {
      debugPrint('Fehler beim Abrufen der Präferenz: $e');
      return null;
    }
  }

  // ----------------------------------------
  // CREATE RECIPE
  // ----------------------------------------
  Future<String> createRecipe(Recipe recipe) async {
    try {
      final Map<String, dynamic> recipeRes = await _db
          .from('recipes')
          .insert({
            'title': recipe.title,
            'description': recipe.description,
            'image_url': recipe.imageUrl,
            'duration_minutes': recipe.durationMinutes,
            'servings': recipe.servings,
            'difficulty': recipe.difficulty.name[0].toUpperCase() +
                recipe.difficulty.name.substring(1),
            'meal_type': recipe.mealType != null ? Recipe.mealTypeToString(recipe.mealType!) : null,
            'owner_id': userId,
          })
          .select()
          .single();  

      final String recipeId = _id(recipeRes['id']);
      if (recipeId.isEmpty) {
        throw StateError("createRecipe: recipeId vide après insertion.");
      }

      // nutrition
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

      // steps
      for (final step in recipe.steps) {
        await _db.from('recipe_steps').insert({
          'recipe_id': recipeId,
          'step_number': step.stepNumber,
          'instruction': step.instruction,
        });
      }

      // ingredients
      for (final ing in recipe.ingredients) {
        final Map<String, dynamic>? existingIng = await _db
            .from('ingredients')
            .select('id')
            .eq('name', ing.name)
            .maybeSingle();

        String ingredientId;

        if (existingIng == null) {
          final Map<String, dynamic> newIng = await _db
              .from('ingredients')
              .insert({'name': ing.name})
              .select('id')
              .single();
          ingredientId = _id(newIng['id']);
        } else {
          ingredientId = _id(existingIng['id']);
        }

        await _db.from('recipe_ingredients').insert({
          'recipe_id': recipeId,
          'ingredient_id': ingredientId,
          'quantity': ing.quantity,
          'unit': ing.unit,
        });
      }

      // tags
      for (final tagName in recipe.tags) {
        final Map<String, dynamic>? tag = await _db
            .from('tags')
            .select('id')
            .eq('name', tagName)
            .maybeSingle();

        String tagId;

        if (tag == null) {
          final Map<String, dynamic> newTag = await _db
              .from('tags')
              .insert({'name': tagName})
              .select('id')
              .single();
          tagId = _id(newTag['id']);
        } else {
          tagId = _id(tag['id']);
        }

        await _db.from('recipe_tags').insert({
          'recipe_id': recipeId,
          'tag_id': tagId,
        });
      }

      return recipeId;
    } catch (e) {
      debugPrint("ERROR createRecipe(): $e");
      rethrow;
    }
  }

  // ----------------------------------------
  // UPDATE RECIPE (owner only)
  // ----------------------------------------
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      final String recipeId = _id(recipe.id);
      if (recipeId.isEmpty) {
        throw ArgumentError("updateRecipe: recipe.id est null ou vide.");
      }

      await _db.from('recipes').update({
        'title': recipe.title,
        'description': recipe.description,
        'image_url': recipe.imageUrl,
        'duration_minutes': recipe.durationMinutes,
        'servings': recipe.servings,
        'difficulty': recipe.difficulty.name[0].toUpperCase() +
            recipe.difficulty.name.substring(1),
        'meal_type': recipe.mealType != null ? Recipe.mealTypeToString(recipe.mealType!) : null,
      }).eq('id', recipeId).eq('owner_id', userId);

      // nutrition (delete + insert)
      await _db.from('nutrition').delete().eq('recipe_id', recipeId);
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

      // steps (delete + insert)
      await _db.from('recipe_steps').delete().eq('recipe_id', recipeId);
      for (final step in recipe.steps) {
        await _db.from('recipe_steps').insert({
          'recipe_id': recipeId,
          'step_number': step.stepNumber,
          'instruction': step.instruction,
        });
      }

      // ingredients relations (delete + insert)
      await _db.from('recipe_ingredients').delete().eq('recipe_id', recipeId);
      for (final ing in recipe.ingredients) {
        final Map<String, dynamic>? existingIng = await _db
            .from('ingredients')
            .select('id')
            .eq('name', ing.name)
            .maybeSingle();

        String ingredientId;
        if (existingIng == null) {
          final Map<String, dynamic> newIng = await _db
              .from('ingredients')
              .insert({'name': ing.name})
              .select('id')
              .single();
          ingredientId = _id(newIng['id']);
        } else {
          ingredientId = _id(existingIng['id']);
        }

        await _db.from('recipe_ingredients').insert({
          'recipe_id': recipeId,
          'ingredient_id': ingredientId,
          'quantity': ing.quantity,
          'unit': ing.unit,
        });
      }

      // tags relations (delete + insert)
      await _db.from('recipe_tags').delete().eq('recipe_id', recipeId);
      for (final tagName in recipe.tags) {
        final Map<String, dynamic>? tag = await _db
            .from('tags')
            .select('id')
            .eq('name', tagName)
            .maybeSingle();

        String tagId;
        if (tag == null) {
          final Map<String, dynamic> newTag = await _db
              .from('tags')
              .insert({'name': tagName})
              .select('id')
              .single();
          tagId = _id(newTag['id']);
        } else {
          tagId = _id(tag['id']);
        }

        await _db.from('recipe_tags').insert({
          'recipe_id': recipeId,
          'tag_id': tagId,
        });
      }
    } catch (e) {
      debugPrint("ERROR updateRecipe(): $e");
      rethrow;
    }
  }

  // ----------------------------------------
  // DELETE RECIPE (owner only)
  // ----------------------------------------
  Future<void> deleteRecipe(String recipeId) async {
    try {
      final existing = await _db
          .from('recipes')
          .select('id, owner_id')
          .eq('id', recipeId)
          .maybeSingle();

      if (existing == null) return;

      final owner = _id(existing['owner_id']);
      if (owner != userId) {
        throw StateError("Vous ne pouvez supprimer que vos propres recettes.");
      }

      await _db.from('recipe_tags').delete().eq('recipe_id', recipeId);
      await _db.from('recipe_ingredients').delete().eq('recipe_id', recipeId);
      await _db.from('recipe_steps').delete().eq('recipe_id', recipeId);
      await _db.from('nutrition').delete().eq('recipe_id', recipeId);
      await _db.from('ratings').delete().eq('recipe_id', recipeId);
      await _db.from('user_favorites').delete().eq('recipe_id', recipeId);

      await _db.from('recipes').delete().eq('id', recipeId).eq('owner_id', userId);
    } catch (e) {
      debugPrint("ERROR deleteRecipe(): $e");
      rethrow;
    }
  }

  // ----------------------------------------
  // FAVORITES
  // ----------------------------------------
Future<bool> isRecipeFavorite(String recipeId) async {
    try {
      final Map<String, dynamic>? existing = await _db
          .from('user_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('recipe_id', recipeId)
          .maybeSingle();

      return existing != null;
    } catch (e) {
      debugPrint("ERROR _isFavorite: $e");
      return false;
    }
  }


  Future<void> toggleFavorite(String recipeId) async {
    try {
      final bool currentlyFavorite = await isRecipeFavorite(recipeId);

      if (currentlyFavorite) {
        await _db
            .from('user_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('recipe_id', recipeId);
      } else {
        await _db.from('user_favorites').insert({
          'user_id': userId,
          'recipe_id': recipeId,
        });
      }
    } catch (e) {
      debugPrint("ERROR toggleFavorite: $e");
      rethrow;
    }
  }

  Future<Set<String>> fetchUserFavorites() async {
    if (userId.isEmpty) return {};

    try {
      final dynamic response = await _db
          .from('user_favorites')
          .select('recipe_id')
          .eq('user_id', userId);

      final List list = response as List;
      return list.map((item) => _id(item['recipe_id'])).toSet();
    } catch (e) {
      debugPrint("ERROR fetchUserFavorites(): $e");
      return {};
    }
  }

 // ----------------------------------------
  // FETCH RECIPES 
  // ----------------------------------------
  Future<List<Recipe>> fetchAllRecipes({required RecipeFilter filter}) async {
    if (userId.isEmpty) return [];

    const String selectQuery = '''
      *,
      ownername,
      nutrition(*),
      recipe_ingredients(*, ingredients(*)),
      recipe_steps(*),
      recipe_tags(*, tags(*))
    ''';

    try {
      List<dynamic> data;

      if (filter == RecipeFilter.favorite) {
        // 1. Get favorite IDs
        final favoriteResponse = await _db
            .from('user_favorites')
            .select('recipe_id')
            .eq('user_id', userId);

        final List favoriteList = favoriteResponse as List;
        final List<String> favoriteRecipeIds =
            favoriteList.map((f) => _id(f['recipe_id'])).toList();

        if (favoriteRecipeIds.isEmpty) {
          data = [];
        } else {
          // 2. Fetch full data using 'dynamic' to avoid type errors
          dynamic query = _db
              .from('recipes_with_owner')
              .select(selectQuery)
              .inFilter('id', favoriteRecipeIds)
              .order('created_at', ascending: false);
          
          data = await query;
        }
      } else {
        // Declare as 'dynamic' to allow switching between Filter and Transform builders
        dynamic query = _db.from('recipes_with_owner').select(selectQuery);

        switch (filter) {
          case RecipeFilter.mine:
            query = query.eq('owner_id', userId).order('created_at', ascending: false);
            break;

          case RecipeFilter.newest:
            // Datum für die letzten 7 Tage berechnen
            final lastWeek = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
            
            // Ernährungspräferenz des Benutzers abrufen
            final dietPreference = await getUserDietPreference();
            debugPrint('DEBUG: Benutzer-Präferenz = $dietPreference');
            
            // Filter anwenden: nur Rezepte anderer Benutzer
            query = query
                .neq('owner_id', userId)
                .gte('created_at', lastWeek)
                .order('created_at', ascending: false);
            
            // Ergebnisse abrufen
            final response = await query;
            var filteredData = response as List<dynamic>;
            debugPrint('DEBUG: Rezepte vor Filter = ${filteredData.length}');
            
            // Nach Ernährungspräferenz filtern (wenn vorhanden und nicht "Keine")
            if (dietPreference != null && dietPreference != 'Keine') {
              filteredData = filteredData.where((recipe) {
                // Tags aus recipe_tags extrahieren
                final recipeTags = recipe['recipe_tags'] as List<dynamic>? ?? [];
                final tagNames = recipeTags
                    .map((rt) => rt['tags']?['name']?.toString().toLowerCase() ?? '')
                    .toList();
                debugPrint('DEBUG: Rezept "${recipe['title']}" hat Tags: $tagNames');
                
                // Prüfen ob ein Tag der Präferenz entspricht
                return tagNames.any((tag) => 
                  tag.contains(dietPreference.toLowerCase())
                );
              }).toList();
            }
            
            debugPrint('DEBUG: Rezepte nach Filter = ${filteredData.length}');
            
            return filteredData
                .map((json) => Recipe.fromJson(json as Map<String, dynamic>))
                .toList();

          case RecipeFilter.popular:
            query = query
                .order('average_rating', ascending: false)
                .order('total_ratings', ascending: false);
            break;

          case RecipeFilter.all:
          default:
            query = query.order('title', ascending: true);
            break;
        }

        final response = await query;
        data = response as List<dynamic>;
      }

      // Convert the JSON list to a Recipe list efficiently
      return data.map((json) => Recipe.fromJson(json as Map<String, dynamic>)).toList();

    } catch (e) {
      debugPrint("ERROR fetchAllRecipes(): $e");
      return [];
    }
  }

  // RATINGS

  Future<int?> fetchUserRating(String recipeId) async {
    try {
      final dynamic res = await _db
          .from('ratings')
          .select('score')
          .eq('recipe_id', recipeId)
          .eq('user_id', userId)
          .maybeSingle();

      if (res == null) return null;

      final Map<String, dynamic> data = res as Map<String, dynamic>;
      final score = data['score'];
      if (score == null) return null;

      return (score as num).toInt();
    } catch (e) {
      debugPrint("ERROR fetchUserRating(): $e");
      return null;
    }
  }

  // Liste des ratings (avec user_email via vue ratings_with_users si vous l’avez)
  Future<List<Map<String, dynamic>>> fetchAllRatingsForRecipe(String recipeId) async {
    try {
      final dynamic data = await _db
          .from('ratings_with_users')
          .select('score, comment, created_at, username')
          .eq('recipe_id', recipeId)
          .order('created_at', ascending: false);

      final List list = data as List;
      return list.map((rating) {
        final r = rating as Map<String, dynamic>;
        return {
          'score': r['score'],
          'comment': r['comment'],
          'created_at': r['created_at'],
          'user_name': r['username'] ?? 'Anonymous',
        };
      }).toList();
    } catch (e) {
      debugPrint('ERROR fetchAllRatingsForRecipe(): $e');
      rethrow;
    }
  }

  // Upsert rating + recalcul stats
  Future<Map<String, dynamic>> rateRecipe({
    required String recipeId,
    required int score,
    String? comment,
  }) async {
    try {
      await _db.from('ratings').upsert({
        'recipe_id': recipeId,
        'user_id': userId,
        'score': score,
        'comment': comment,
      });

      final dynamic res = await _db
          .from('ratings')
          .select('score')
          .eq('recipe_id', recipeId);

      final List rows = res as List;
      if (rows.isEmpty) {
        return {'average': 0.0, 'total': 0};
      }

      double totalScore = 0;
      for (final row in rows) {
        totalScore += ((row as Map<String, dynamic>)['score'] as num).toDouble();
      }

      final int newTotalRatings = rows.length;
      final double newAverage =
          double.parse((totalScore / newTotalRatings).toStringAsFixed(1));

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

  Future<Map<String, num>> fetchRecipeStats(String recipeId) async {
    try {
      final dynamic data = await _db
          .from('recipes')
          .select('average_rating, total_ratings')
          .eq('id', recipeId)
          .single();

      final Map<String, dynamic> row = data as Map<String, dynamic>;

      return {
        'average': (row['average_rating'] as num?) ?? 0.0,
        'total': (row['total_ratings'] as num?) ?? 0,
      };
    } catch (e) {
      debugPrint('ERROR fetchRecipeStats(): $e');
      return {'average': 0.0, 'total': 0};
    }
  }

  // ----------------------------------------
  // STORAGE: upload image
  // ----------------------------------------
  Future<String?> uploadRecipeImage(Uint8List imageBytes, String fileName) async {
    try {
      final fileExt = fileName.split('.').last;
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = '$userId/$uniqueFileName';

      await _db.storage.from('recipe-images').uploadBinary(
            storagePath,
            imageBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final String publicUrl =
          _db.storage.from('recipe-images').getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      debugPrint('ERROR uploadRecipeImage(): $e');
      return null;
    }
  }

  // ============================================
  // WEEK PLAN METHODS
  // ============================================

  DateTime _getMondayOfWeek(DateTime date) {
    final dayOfWeek = date.weekday;
    return date.subtract(Duration(days: dayOfWeek - 1));
  }

  String _dayToEnglish(String germanDay) {
    const Map<String, String> dayMap = {
      'Montag': 'Monday',
      'Dienstag': 'Tuesday',
      'Mittwoch': 'Wednesday',
      'Donnerstag': 'Thursday',
      'Freitag': 'Friday',
      'Samstag': 'Saturday',
      'Sonntag': 'Sunday',
    };
    return dayMap[germanDay] ?? germanDay;
  }

  String _mealToEnglish(String germanMeal) {
    const Map<String, String> mealMap = {
      'Frühstück': 'Breakfast',
      'Mittagessen': 'Lunch',
      'Abendessen': 'Dinner',
    };
    return mealMap[germanMeal] ?? germanMeal;
  }

  Future<void> saveWeekPlan(Map<String, Map<String, String?>> weekPlan) async {
    
    try {
      final monday = _getMondayOfWeek(DateTime.now());
      final weekStartDate = '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';

      await _db.from('week_plan').delete().eq('user_id', userId).eq('week_start_date', weekStartDate);

      final List<Map<String, dynamic>> dataToInsert = [];
      weekPlan.forEach((day, meals) {
        meals.forEach((mealType, recipeId) {
          if (recipeId != null && recipeId.isNotEmpty) {
            dataToInsert.add({
              'user_id': userId,
              'week_start_date': weekStartDate,
              'day_of_week': _dayToEnglish(day),
              'meal_type': _mealToEnglish(mealType),
              'recipe_id': recipeId,
            });
          }
        });
      });

      if (dataToInsert.isNotEmpty) {
        await _db.from('week_plan').insert(dataToInsert);
      }
    } catch (e) {
      debugPrint('Error saving week plan: $e');
      rethrow;
    }
  }

  Future<Map<String, Map<String, String?>>> loadWeekPlan() async {
    
    try {
      final monday = _getMondayOfWeek(DateTime.now());
      final weekStartDate = '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';

      final response = await _db.from('week_plan').select('day_of_week, meal_type, recipe_id').eq('user_id', userId).eq('week_start_date', weekStartDate);

      final Map<String, Map<String, String?>> weekPlan = {};

      const Map<String, String> dayMap = {
        'Monday': 'Montag', 'Tuesday': 'Dienstag', 'Wednesday': 'Mittwoch',
        'Thursday': 'Donnerstag', 'Friday': 'Freitag', 'Saturday': 'Samstag', 'Sunday': 'Sonntag',
      };

      const Map<String, String> mealMap = {
        'Breakfast': 'Frühstück', 'Lunch': 'Mittagessen', 'Dinner': 'Abendessen',
      };

      for (var entry in response) {
        final day = dayMap[entry['day_of_week']] ?? entry['day_of_week'];
        final mealType = mealMap[entry['meal_type']] ?? entry['meal_type'];
        final recipeId = entry['recipe_id'] as String?;

        if (!weekPlan.containsKey(day)) weekPlan[day] = {};
        weekPlan[day]![mealType] = recipeId;
      }

      return weekPlan;
    } catch (e) {
      debugPrint('Error loading week plan: $e');
      rethrow;
    }
  }

  Future<Recipe?> getRecipeById(String recipeId) async {
    try {
      final response = await _db.from('recipes').select().eq('id', recipeId).single();
      return Recipe.fromJson(response);
    } catch (e) {
      debugPrint('Error getting recipe by ID: $e');
      return null;
    }
  }

// fetch shopping list items for current user
Future<List<Map<String, dynamic>>> fetchShoppingList() async {
  final res = await _db
      .from('shopping_list')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: true);
  return List<Map<String, dynamic>>.from(res);
}

// add a new item to shopping list
Future<void> addToShoppingList(String name, double qty, String unit) async {
  try {
    // 1. Chercher si l'ingrédient existe déjà (et n'est pas encore acheté)
    final existingItems = await _db
        .from('shopping_list')
        .select()
        .eq('user_id', userId)
        .eq('name', name)
        .eq('is_bought', false);

    if (existingItems.isNotEmpty) {
      // 2. Si l'article existe, on additionne proprement les nombres
      final existing = existingItems.first;
      double currentQty = (existing['quantity'] as num).toDouble();
      
      await _db.from('shopping_list').update({
        'quantity': currentQty + qty,
      }).eq('id', existing['id']);
      
    } else {
      // 3. Sinon, on crée une nouvelle ligne
      await _db.from('shopping_list').insert({
        'user_id': userId,
        'name': name,
        'quantity': qty,
        'unit': unit,
        'is_bought': false,
      });
    }
  } catch (e) {
    debugPrint("Erreur lors de l'ajout à la liste : $e");
  }
}
// update item 
Future<void> updateShoppingItemStatus(String id, bool isBought) async {
  await _db.from('shopping_list').update({'is_bought': isBought}).eq('id', id);
}

// update items details
Future<void> updateShoppingItemDetails(String id, String name, double quantity) async {
  await _db.from('shopping_list').update({
    'name': name,
    'quantity': quantity,
  }).eq('id', id);
}

// delete a shopping item
Future<void> deleteShoppingItem(String id) async {
  await _db.from('shopping_list').delete().eq('id', id);
}
// clear entire shopping list for current user

Future<void> clearShoppingList() async {
  try {
    await _db.from('shopping_list').delete().eq('user_id', userId);
  } catch (e) {
    debugPrint("Fehler beim Löschen der Liste: $e");
    rethrow;
  }
}

}
