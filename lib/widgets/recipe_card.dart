import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'common_widgets.dart';

/// A card widget representing a single recipe in a list.
/// Updated for responsiveness and favorite functionality.
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  
  // NEW: State for favorite
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const RecipeCard({
    super.key, 
    required this.recipe, 
    required this.onTap,
    required this.isFavorite,
    required this.onFavoriteToggle,
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
            // 1. Image Section with Favorite Button
            Stack(
              children: [
                // RESPONSIVENESS FIX: AspectRatio forces a 16:9 ratio
                // regardless of screen width (Web vs Mobile)
                AspectRatio(
                  aspectRatio: 16 / 9, 
                  child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                      ? Image.network(
                          recipe.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),

                // FAVORITE BUTTON: Positioned top-right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7), // Semi-transparent background
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey[800],
                      ),
                      onPressed: onFavoriteToggle,
                    ),
                  ),
                ),
              ],
            ),
            
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
                  
                  // Metadata Row
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
                  
                  // Tags Row
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

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.restaurant, size: 60, color: Colors.grey),
      ),
    );
  }
}