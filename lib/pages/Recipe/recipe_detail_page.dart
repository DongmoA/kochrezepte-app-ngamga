// lib/pages/recipe/recipe_detail_page.dart

import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../supabase/database_service.dart';
import '../../widgets/recipe_detail_items.dart';
import '../../widgets/rating_widget.dart';
import 'recipe_form_page.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final DatabaseService _db = DatabaseService();

  bool get _isMine =>
      widget.recipe.ownerId != null && widget.recipe.ownerId == _db.userId;

  Future<void> _editRecipe() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeFormPage(recipeToEdit: widget.recipe),
      ),
    );

    // Si update OK: on retourne true pour refresh la liste
    if (updated == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rezept löschen?"),
        content: const Text("Diese Aktion kann nicht rückgängig gemacht werden."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text("Löschen"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final id = widget.recipe.id;
      if (id == null || id.isEmpty) return;

      await _db.deleteRecipe(id);

      if (mounted) {
        Navigator.pop(context, true); // refresh home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Fehler: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.orange,
            actions: [
              if (_isMine) ...[
                IconButton(
                  tooltip: "Bearbeiten",
                  icon: const Icon(Icons.edit),
                  onPressed: _editRecipe,
                ),
                IconButton(
                  tooltip: "Löschen",
                  icon: const Icon(Icons.delete),
                  onPressed: _confirmDelete,
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
              background: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                  ? Image.network(
                      recipe.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetadataSection(recipe),
                  const SizedBox(height: 24),

                  RecipeRatingWidget(recipe: recipe),

                  if (recipe.tags.isNotEmpty) ...[
                    _buildTagsSection(recipe),
                    const SizedBox(height: 24),
                  ],

                  if (_hasNutritionInfo(recipe)) ...[
                    _buildNutritionSection(recipe),
                    const SizedBox(height: 24),
                  ],

                  const Text(
                    'Ingredients',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...recipe.ingredients
                      .map((ing) => IngredientItem(ingredient: ing)),
                  const SizedBox(height: 24),

                  const Text(
                    'Preparation',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...recipe.steps.map((step) => StepItem(step: step)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.restaurant, size: 80, color: Colors.grey),
      ),
    );
  }

  Widget _buildMetadataSection(Recipe recipe) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetadataItem(
              Icons.access_time,
              '${recipe.durationMinutes} Min',
              'Duration',
            ),
            _buildMetadataItem(
              Icons.restaurant,
              '${recipe.servings}',
              'Servings',
            ),
            _buildMetadataItem(
              Icons.signal_cellular_alt,
              _getDifficultyLabel(recipe),
              'Difficulty',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.orange),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTagsSection(Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recipe.tags.map((tag) {
            return Chip(
              label: Text(tag),
              backgroundColor: Colors.orange[100],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNutritionSection(Recipe recipe) {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nutrition per serving',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (recipe.calories != null)
                  NutritionInfoItem(
                      label: 'Calories',
                      value: '${recipe.calories}',
                      unit: 'kcal'),
                if (recipe.protein != null)
                  NutritionInfoItem(
                      label: 'Protein',
                      value: '${recipe.protein}',
                      unit: 'g'),
                if (recipe.carbs != null)
                  NutritionInfoItem(
                      label: 'Carbs', value: '${recipe.carbs}', unit: 'g'),
                if (recipe.fat != null)
                  NutritionInfoItem(
                      label: 'Fat', value: '${recipe.fat}', unit: 'g'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDifficultyLabel(Recipe recipe) {
    return recipe.difficulty.name[0].toUpperCase() +
        recipe.difficulty.name.substring(1);
  }

  bool _hasNutritionInfo(Recipe recipe) {
    return recipe.calories != null ||
        recipe.protein != null ||
        recipe.carbs != null ||
        recipe.fat != null;
  }
}
