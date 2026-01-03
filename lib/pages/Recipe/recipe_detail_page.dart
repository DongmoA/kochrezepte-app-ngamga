import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../widgets/recipe_detail_items.dart';
import '../../widgets/rating_widget.dart';
import '../../supabase/database_service.dart'; 
import 'package:share_plus/share_plus.dart';


class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final DatabaseService _dbService = DatabaseService(); 
  
  // Variables locales pour piloter l'affichage dynamique en haut
  late double _currentAverage;
  late int _currentTotal;
  bool _isLoadingStats = true; 

  @override
  void initState() {
    super.initState();
    // On initialise avec les valeurs actuelles de la recette
    _currentAverage = widget.recipe.averageRating;
    _currentTotal = widget.recipe.totalRatings;
    _refreshStats(); 
  }

  //
  Future<void> _refreshStats() async {
    try {
      final stats = await _dbService.fetchRecipeStats(widget.recipe.id!);
      
      if (mounted) {
        setState(() {
          _currentAverage = (stats['average'] as num).toDouble();
          _currentTotal = (stats['total'] as num).toInt();
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur refresh stats: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }
  
  // a method to share the recipe details
Future<void> _shareRecipe() async {
  final String message = '''
🍳 ${widget.recipe.title}

⏱️ ${widget.recipe.durationMinutes} Min | 👥 ${widget.recipe.servings} Servings | ⭐ ${_currentAverage.toStringAsFixed(1)} ($_currentTotal Ratings)

Check out this delicious recipe!
  '''.trim();
  final ShareParams messageParams = ShareParams(
    text: message,
    subject: widget.recipe.title,
  );
  
  await SharePlus.instance.share(messageParams);
}

// Widget to show creator info
Widget _buildCreatorInfo() {
 
  if (widget.recipe.ownerEmail == null) return const SizedBox.shrink();
 
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      children: [
        const Icon(Icons.person_outline, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          'Created by ${widget.recipe.ownerEmail}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    ),
  );
}

// Widget to show share button
Widget _buildShareButton() {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: OutlinedButton.icon(
      onPressed: _shareRecipe,
      icon: const Icon(Icons.share, size: 16),
      label: const Text('Share', style: TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: const BorderSide(color: Colors.grey),
      ),
    ),
  );
}

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: const Text('Rezept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image sous l'appbar
            SizedBox(
              width: double.infinity,
              height: 200,
              child: widget.recipe.imageUrl != null && widget.recipe.imageUrl!.isNotEmpty
                  ? Image.network(widget.recipe.imageUrl!, fit: BoxFit.cover)
                  : Container(color: Colors.grey[300], child: const Icon(Icons.restaurant, size: 50)),
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // CARD 1 : Titel, Bewertung (Dynamique), Tags
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.recipe.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        
                        // 
                        _isLoadingStats 
                          ? const SizedBox(
                              height: 20,
                              child: Center(
                                child: SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                                ),
                              ),
                            )
                          : _buildRatingSummary(_currentAverage, _currentTotal),
                        
                        const SizedBox(height: 12),
                        _buildCompactStats(),
                        
                        if (widget.recipe.tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            children: widget.recipe.tags.map((tag) => _buildTagChip(tag)).toList(),
                          ),
                        ],
                        _buildCreatorInfo(),
                        _buildShareButton(),
                      ],
                    ),
                  ),

                  // CARD 2 : Nährwerte
                  if (_hasNutritionInfo())
                    _buildSectionCard(
                      title: "Nährwerte pro Portion",
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.recipe.calories != null) _buildNutritionMini(widget.recipe.calories.toString(), "kcal", "Kalorien"),
                          if (widget.recipe.protein != null) _buildNutritionMini(widget.recipe.protein.toString(), "g", "Protein"),
                          if (widget.recipe.carbs != null) _buildNutritionMini(widget.recipe.carbs.toString(), "g", "Carbs"),
                          if (widget.recipe.fat != null) _buildNutritionMini(widget.recipe.fat.toString(), "g", "Fett"),
                        ],
                      ),
                    ),

                  _buildSectionCard(title: "Zutaten", child: Column(children: widget.recipe.ingredients.map((ing) => IngredientItem(ingredient: ing)).toList())),
                  _buildSectionCard(title: "Zubereitung", child: Column(children: widget.recipe.steps.map((step) => StepItem(step: step)).toList())),
                  
                  // CARD : Ratings avec Callback pour mettre à jour le haut
                  _buildSectionCard(
                    title: "Bewertungen", 
                    child: RecipeRatingWidget(
                      recipe: widget.recipe,
                      onRaitingSucess: (newAvg, newTotal) {
                        setState(() {
                          _currentAverage = newAvg;
                          _currentTotal = newTotal;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Affichage des étoiles et du total mis à jour
  Widget _buildRatingSummary(double avg, int total) {
    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < avg.round() ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 18,
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          '${avg.toStringAsFixed(1)} ($total)',
          style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Les fonctions d'aide (inchangées)
  Widget _buildSectionCard({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const Divider(height: 20, thickness: 0.5),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildCompactStats() {
    return Row(
      children: [
        const Icon(Icons.access_time, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text('${widget.recipe.durationMinutes} Min', style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 16),
        const Icon(Icons.people_outline, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text('${widget.recipe.servings} Personen', style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
      child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
    );
  }

  Widget _buildNutritionMini(String value, String unit, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text("$value $unit", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  bool _hasNutritionInfo() => widget.recipe.calories != null;
}