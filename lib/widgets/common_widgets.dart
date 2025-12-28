import 'package:flutter/material.dart';
import '../models/recipe.dart';

/// A widget to display the difficulty level with a specific color code.
/// Used in both the RecipeCard and potentially the DetailPage.
class DifficultyBadge extends StatelessWidget {
  final Difficulty difficulty;

  const DifficultyBadge({super.key, required this.difficulty});

  /// Returns the color associated with the difficulty level.
  Color _getDifficultyColor() {
    switch (difficulty) {
      case Difficulty.einfach:
        return Colors.green;
      case Difficulty.mittel:
        return Colors.orange;
      case Difficulty.schwer:
        return Colors.red;
    }
  }

  /// Returns the localized label for the difficulty.
  String _getDifficultyLabel() {
    switch (difficulty) {
      case Difficulty.einfach:
        return 'Einfach';
      case Difficulty.mittel:
        return 'Mittel';
      case Difficulty.schwer:
        return 'Schwer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getDifficultyColor();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getDifficultyLabel(),
        style: TextStyle(
          fontSize: 12,
          color: color.withValues(alpha:  0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// A simple chip displaying an icon and a text label side by side.
/// Used primarily in the RecipeCard.
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label, 
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}