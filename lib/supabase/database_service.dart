// lib/supabase/database_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/recipe.dart';
import 'supabase_client.dart';
import 'auth_service.dart';

class DatabaseService {
  final SupabaseClient _db = SupabaseClientManager.client;
  final AuthService _authService = AuthService();

  String get userId => _authService.getCurrentUserId();

  // Helper: convertit n'importe quel id Supabase (int/uuid) en String
  String _id(dynamic value) => value?.toString() ?? '';

  /// Create a full recipe with ingredients, steps, tags and nutrition
  Future<String> createRecipe(Recipe recipe) async {
    try {
      final Map<String, dynamic> recipeRes = await _db
          .from('recipes')
          .insert({
            'title': recipe.title,
            'image_url': recipe.imageUrl,
            'duration_minutes': recipe.durationMinutes,
            'servings': recipe.servings,
            'difficulty': recipe.difficulty.name[0].toUpperCase() +
                recipe.difficulty.name.substring(1),
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

  // -----------------------------
  // UPDATE RECIPE (owner only)
  // -----------------------------
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      final String recipeId = _id(recipe.id);
      if (recipeId.isEmpty) {
        throw ArgumentError("updateRecipe: recipe.id est null ou vide.");
      }

      // IMPORTANT: ne modifie que si owner_id = userId
      await _db.from('recipes').update({
        'title': recipe.title,
        'image_url': recipe.imageUrl,
        'duration_minutes': recipe.durationMinutes,
        'servings': recipe.servings,
        'difficulty': recipe.difficulty.name[0].toUpperCase() +
            recipe.difficulty.name.substring(1),
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

  // -----------------------------
  // DELETE RECIPE (owner only)
  // -----------------------------
  Future<void> deleteRecipe(String recipeId) async {
    try {
      // Vérifie ownership
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

      // Delete related data
      await _db.from('recipe_tags').delete().eq('recipe_id', recipeId);
      await _db.from('recipe_ingredients').delete().eq('recipe_id', recipeId);
      await _db.from('recipe_steps').delete().eq('recipe_id', recipeId);
      await _db.from('nutrition').delete().eq('recipe_id', recipeId);
      await _db.from('ratings').delete().eq('recipe_id', recipeId);
      await _db.from('user_favorites').delete().eq('recipe_id', recipeId);

      // Delete recipe (owner constraint)
      await _db.from('recipes').delete().eq('id', recipeId).eq('owner_id', userId);
    } catch (e) {
      debugPrint("ERROR deleteRecipe(): $e");
      rethrow;
    }
  }

  /// Toggles the favorite status of a recipe for the current user.
  Future<void> toggleFavorite(String recipeId) async {
    try {
      final Map<String, dynamic>? existing = await _db
          .from('user_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('recipe_id', recipeId)
          .maybeSingle();

      if (existing != null) {
        await _db.from('user_favorites').delete().eq('id', existing['id']);
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

  /// Retrieves the list of favorite recipe IDs for the current user.
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

  Future<List<Recipe>> fetchAllRecipes({required RecipeFilter filter}) async {
    if (userId.isEmpty) return [];

    const String selectQuery = '''
      *,
      nutrition(*),
      recipe_ingredients(*, ingredients(*)),
      recipe_steps(*),
      recipe_tags(*, tags(*))
    ''';

    try {
      List<dynamic> data;

      if (filter == RecipeFilter.favorite) {
        final dynamic response = await _db
            .from('user_favorites')
            .select('recipes($selectQuery)')
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        final List list = response as List;
        data = list.map((e) => e['recipes']).where((x) => x != null).toList();
      } else {
        dynamic query = _db.from('recipes').select(selectQuery);

        switch (filter) {
          case RecipeFilter.mine:
            query = query.eq('owner_id', userId).order('created_at', ascending: false);
            break;
          case RecipeFilter.newest:
            query = query.order('created_at', ascending: false);
            break;
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

        final dynamic response = await query;
        data = response as List<dynamic>;
      }

      return data
          .map((json) => Recipe.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("ERROR fetchAllRecipes(): $e");
      return [];
    }
  }

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

  Future<void> rateRecipe({required String recipeId, required int score}) async {
    try {
      await _db.from('ratings').upsert({
        'recipe_id': recipeId,
        'user_id': userId,
        'score': score,
      });

      final dynamic res = await _db
          .from('ratings')
          .select('score')
          .eq('recipe_id', recipeId);

      final List rows = res as List;
      if (rows.isEmpty) return;

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

      debugPrint("Rating successful. New average: $newAverage ($newTotalRatings votes)");
    } catch (e) {
      debugPrint("ERROR rateRecipe(): $e");
      rethrow;
    }
  }
}
