import 'package:flutter/material.dart';
import '../models/recipe.dart';

class IngredientItem extends StatelessWidget {
  final RecipeIngredient ingredient;

  const IngredientItem({super.key, required this.ingredient});

  @override
 Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        const Text("•", style: TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${ingredient.quantity} ${ingredient.unit} ${ingredient.name}',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    ),
  );
}
}

class StepItem extends StatelessWidget {
  final RecipeStep step;

  const StepItem({super.key, required this.step});

  @override
 Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${step.stepNumber}. ', 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
        Expanded(
          child: Text(step.instruction, 
            style: const TextStyle(fontSize: 14, height: 1.4)),
        ),
      ],
    ),
  );
}
}

class NutritionInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const NutritionInfoItem({super.key, required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          '$value $unit',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}