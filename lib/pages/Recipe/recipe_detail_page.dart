
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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
  final DatabaseService _dbService = DatabaseService();

  bool get _isMine =>
      widget.recipe.ownerId != null && widget.recipe.ownerId == _dbService.userId;

  late double _currentAverage;
  late int _currentTotal;
  bool _isLoadingStats = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _currentAverage = widget.recipe.averageRating;
    _currentTotal = widget.recipe.totalRatings;
    _refreshStats();
    _checkFavoriteStatus();
  }


// Check if recipe is favorite
  Future<void> _checkFavoriteStatus() async {
    try {
      final isFav = await _dbService.isRecipeFavorite(widget.recipe.id!);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    } catch (e) {
      debugPrint('Error check for favorite status: $e');
    }
  }

  // Toggle favorite status
Future<void> _handleToggleFavorite() async {
    try {
      await _dbService.toggleFavorite(widget.recipe.id!);
      setState(() => _isFavorite = !_isFavorite);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isFavorite ? 'Gespeichert!' : 'Entfernt!')),
        );
      }
    } catch (e) {
      debugPrint("Error toggle favorite: $e");
    }
  }

// Add recipe to weekly plan
  Future<void> _showAddToWeeklyPlanDialog() async {
    final List<String> days = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
    final List<String> meals = ['Frühstück', 'Mittagessen', 'Abendessen'];

    String selectedDay = days[0];
    String selectedMeal = meals[0];

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Zum Wochenplan hinzufügen"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedDay,
              items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (val) => selectedDay = val!,
              decoration: const InputDecoration(labelText: "Tag"),
            ),
            DropdownButtonFormField<String>(
              initialValue: selectedMeal,
              items: meals.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => selectedMeal = val!,
              decoration: const InputDecoration(labelText: "Mahlzeit"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Abbrechen")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hinzufügen")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // load current plan, update and save
        final currentPlan = await _dbService.loadWeekPlan();
        if (!currentPlan.containsKey(selectedDay)) currentPlan[selectedDay] = {};
        currentPlan[selectedDay]![selectedMeal] = widget.recipe.id!;
        
        await _dbService.saveWeekPlan(currentPlan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Zu $selectedDay ($selectedMeal) hinzugefügt!")),
          );
        }
      } catch (e) {
        debugPrint("Error saving to plan: $e");
      }
    }
  }

  void _handleAddToShoppingList() async {
  try {
      // On boucle sur tous les ingrédients de la recette pour les ajouter à la DB
      for (var ingredient in widget.recipe.ingredients) {
        await _dbService.addToShoppingList(
          ingredient.name, 
          ingredient.quantity, 
          ingredient.unit
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Zutaten zur Einkaufsliste hinzugefügt!")),
        );
      }
    } catch (e) {
      debugPrint("Error adding to shopping list: $e");
    }
  }


  Future<void> _refreshStats() async {
    try {
      final id = widget.recipe.id;
      if (id == null || id.isEmpty) {
        if (mounted) setState(() => _isLoadingStats = false);
        return;
      }

      final stats = await _dbService.fetchRecipeStats(id);

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

  Future<void> _editRecipe() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeFormPage(recipeToEdit: widget.recipe),
      ),
    );

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

      await _dbService.deleteRecipe(id);

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

  Future<void> _shareRecipe() async {
    final String message = '''
🍳 ${widget.recipe.title}

⏱️ ${widget.recipe.durationMinutes} Min | 👥 ${widget.recipe.servings} Servings | ⭐ ${_currentAverage.toStringAsFixed(1)} ($_currentTotal Ratings)

Check out this delicious recipe!
'''.trim();

    final ShareParams params = ShareParams(
      text: message,
      subject: widget.recipe.title,
    );

    await SharePlus.instance.share(params);
  }

  Widget _buildCreatorInfo() {
   
    if (widget.recipe.ownername == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            'von ${widget.recipe.ownername}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

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
    final recipe = widget.recipe;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        elevation: 0,
        title: const Text(
          'Rezept',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isMine) ...[
            IconButton(
              tooltip: "Bearbeiten",
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _editRecipe,
            ),
            IconButton(
              tooltip: "Löschen",
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _confirmDelete,
            ),
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'save': _handleToggleFavorite(); break;
                case 'week': _showAddToWeeklyPlanDialog(); break;
                case 'buy': _handleAddToShoppingList(); break;
                case 'delete': _confirmDelete(); break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(_isFavorite ? Icons.bookmark : Icons.bookmark_border, color: Colors.orange),
                    const SizedBox(width: 10),
                    const Text("Speichern"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'week',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.blue),
                     SizedBox(width: 10),
                    Text("Zu Wochenplan hinzufügen"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'buy',
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.green),
                    const SizedBox(width: 10),
                    Text("Zu Einkaufsliste hinzufügen"),
                  ],
                ),
              ),
              if (_isMine)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                       SizedBox(width: 10),
                      Text("Löschen", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image
            SizedBox(
              width: double.infinity,
              height: 200,
              child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                  ? Image.network(
                      recipe.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, size: 50),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, size: 50),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // CARD 1 : Titel, Bewertung, Tags
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        _isLoadingStats
                            ? const SizedBox(
                                height: 20,
                                child: Center(
                                  child: SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              )
                            : _buildRatingSummary(_currentAverage, _currentTotal),

                        const SizedBox(height: 12),
                        _buildCompactStats(),

                        if (recipe.tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            children: recipe.tags
                                .map((tag) => _buildTagChip(tag))
                                .toList(),
                          ),
                        ],

                        _buildCreatorInfo(),
                        _buildShareButton(),
                      ],
                    ),
                  ),

                  // CARD 2 : Nährwerte
                  if (_hasNutritionInfo(recipe))
                    _buildSectionCard(
                      title: "Nährwerte pro Portion",
                      child: Column(
                        children: [
                          // Erste Reihe: Kalorien und Protein
                          Row(
                            children: [
                              if (recipe.calories != null)
                                _buildNutritionCard(
                                  recipe.calories.toString(),
                                  "kcal",
                                  "Kalorien",
                                ),
                              if (recipe.calories != null) const SizedBox(width: 16),
                              if (recipe.protein != null)
                                _buildNutritionCard(
                                  recipe.protein.toString(),
                                  "g",
                                  "Protein",
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Zweite Reihe: Carbs und Fett
                          Row(
                            children: [
                              if (recipe.carbs != null)
                                _buildNutritionCard(
                                  recipe.carbs.toString(),
                                  "g",
                                  "Carbs",
                                ),
                              if (recipe.carbs != null) const SizedBox(width: 16),
                              if (recipe.fat != null)
                                _buildNutritionCard(
                                  recipe.fat.toString(),
                                  "g",
                                  "Fett",
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  _buildSectionCard(
                    title: "Zutaten",
                    child: Column(
                      children: recipe.ingredients
                          .map((ing) => IngredientItem(ingredient: ing))
                          .toList(),
                    ),
                  ),

                  _buildSectionCard(
                    title: "Zubereitung",
                    child: Column(
                      children: recipe.steps.map((step) => StepItem(step: step)).toList(),
                    ),
                  ),

                  _buildSectionCard(
                    title: "Bewertungen",
                    child: RecipeRatingWidget(
                      recipe: recipe,
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
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
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
        Text('${widget.recipe.durationMinutes} Min',
            style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 16),
        const Icon(Icons.people_outline, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text('${widget.recipe.servings} Personen',
            style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  Widget _buildNutritionCard(String value, String unit, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              "$value $unit",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  /*Widget _buildNutritionMini(String value, String unit, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            "$value $unit",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
*/
  bool _hasNutritionInfo(Recipe recipe) {
    return recipe.calories != null ||
        recipe.protein != null ||
        recipe.carbs != null ||
        recipe.fat != null;
  }
}
