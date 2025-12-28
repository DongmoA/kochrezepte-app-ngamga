import 'package:flutter/material.dart';
import '../models/recipe.dart';

/// Displays a single ingredient row with an icon, quantity, and name.
class IngredientItem extends StatelessWidget {
  final RecipeIngredient ingredient;

  const IngredientItem({super.key, required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${ingredient.quantity} ${ingredient.unit} ${ingredient.name}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a single cooking step with a number badge and instruction text.
class StepItem extends StatelessWidget {
  final RecipeStep step;

  const StepItem({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Number Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${step.stepNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Instruction Text
          Expanded(
            child: Text(
              step.instruction,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a single nutrition fact (Value, Unit, Label) in a vertical column.
class NutritionInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const NutritionInfoItem({
    super.key, 
    required this.label, 
    required this.value, 
    required this.unit
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        Text(
          unit,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}