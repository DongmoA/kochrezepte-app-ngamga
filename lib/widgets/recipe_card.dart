import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'common_widgets.dart';

/// A card widget representing a single recipe in a list.
/// Displays image, title, duration, servings, and tags.
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const RecipeCard({
    super.key, 
    required this.recipe, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Recipe Image Section
            if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
              Image.network(
                recipe.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
              )
            else
              _buildPlaceholderImage(),
            
            // 2. Recipe Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Metadata Row (Duration, Servings, Difficulty)
                  Row(
                    children: [
                      InfoChip(
                        icon: Icons.access_time,
                        label: '${recipe.durationMinutes} Min',
                      ),
                      const SizedBox(width: 8),
                      InfoChip(
                        icon: Icons.restaurant,
                        label: '${recipe.servings} Portionen',
                      ),
                      const SizedBox(width: 8),
                      DifficultyBadge(difficulty: recipe.difficulty),
                    ],
                  ),
                  
                  // Tags Row (Limited to 3)
                  if (recipe.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recipe.tags.take(3).map((tag) {
                        return Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.orange[100],
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a grey placeholder when no image is available or fails to load.
  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.restaurant, size: 60, color: Colors.grey),
      ),
    );
  }
}

