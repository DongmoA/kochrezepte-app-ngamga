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
    margin: EdgeInsets.zero, // Grid handles spacing via mainAxisSpacing/crossAxisSpacing
    clipBehavior: Clip.antiAlias,
    elevation: 2,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
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
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:  0.7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      color: isFavorite ? Colors.orange : Colors.grey[800],
                    ),
                    onPressed: onFavoriteToggle,
                  ),
                ),
              ),
            ],
          ),
          
          // Info Section
          Expanded( // Use Expanded to ensure the column takes up remaining space and handles overflow
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Metadata Row (Simplified for Grid visibility)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      InfoChip(
                        icon: Icons.access_time,
                        label: '${recipe.durationMinutes} min',
                      ),
                      DifficultyBadge(difficulty: recipe.difficulty),
                    ],
                  ),
                ],
              ),
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