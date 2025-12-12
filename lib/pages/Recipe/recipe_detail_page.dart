import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../widgets/recipe_detail_items.dart'; // Import detail-specific widgets
import '../../widgets/rating_widget.dart'; // Import the rating widget

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.orange,
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
          
          // 2. Scrollable Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata (Duration, Servings, Difficulty)
                  _buildMetadataSection(),
                  const SizedBox(height: 24),
                  
                 //  Recipe Rating System
                  RecipeRatingWidget(recipe: recipe),

                  // Tags
                  if (recipe.tags.isNotEmpty) ...[
                    _buildTagsSection(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Nutrition Info
                  if (_hasNutritionInfo()) ...[
                    _buildNutritionSection(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Ingredients List
                  const Text(
                    'Ingredients',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...recipe.ingredients.map((ing) => IngredientItem(ingredient: ing)),
                  const SizedBox(height: 24),
                  
                  // Preparation Steps List
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

  /// Placeholder for when image is missing
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.restaurant, size: 80, color: Colors.grey),
      ),
    );
  }

  /// Section displaying basic stats (Time, Servings, Difficulty)
  Widget _buildMetadataSection() {
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
              _getDifficultyLabel(),
              'Difficulty',
            ),
          ],
        ),
      ),
    );
  }

  /// Helper for metadata column (Icon + Value + Label)
  /// Kept local as it's specific to this header design
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

  Widget _buildTagsSection() {
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

  Widget _buildNutritionSection() {
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
                  NutritionInfoItem(label: 'Calories', value: '${recipe.calories}', unit: 'kcal'),
                if (recipe.protein != null)
                  NutritionInfoItem(label: 'Protein', value: '${recipe.protein}', unit: 'g'),
                if (recipe.carbs != null)
                  NutritionInfoItem(label: 'Carbs', value: '${recipe.carbs}', unit: 'g'),
                if (recipe.fat != null)
                  NutritionInfoItem(label: 'Fat', value: '${recipe.fat}', unit: 'g'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDifficultyLabel() {
    // Simple helper to translate enum to string
    return recipe.difficulty.name[0].toUpperCase() + recipe.difficulty.name.substring(1);
  }

  bool _hasNutritionInfo() {
    return recipe.calories != null ||
        recipe.protein != null ||
        recipe.carbs != null ||
        recipe.fat != null;
  }
}