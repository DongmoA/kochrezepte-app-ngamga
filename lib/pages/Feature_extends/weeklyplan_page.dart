import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../supabase/database_service.dart';

class WeeklyplanPage extends StatefulWidget {
  const WeeklyplanPage({super.key});

  @override
  State<WeeklyplanPage> createState() => _WeeklyplanPageState();
}

class _WeeklyplanPageState extends State<WeeklyplanPage> {
  final DatabaseService _dbService = DatabaseService();

  // Jours de la semaine
  final List<String> _weekDays = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];

  // Repas de la journée
  final List<String> _meals = [
    'Frühstück',
    'Mittagessen',
    'Abendessen',
  ];

  // Stockage des recettes sélectionnées pour chaque jour et repas
  final Map<String, Map<String, Recipe?>> _weekPlan = {};

  // Liste de toutes les recettes (chargées au démarrage)
  List<Recipe> _allRecipes = [];
  bool _isLoadingRecipes = false;

  @override
  void initState() {
    super.initState();
    // Initialiser le plan vide
    for (var day in _weekDays) {
      _weekPlan[day] = {};
      for (var meal in _meals) {
        _weekPlan[day]![meal] = null;
      }
    }
    // Charger les recettes et le plan de la semaine
    _loadRecipes();
    _loadWeekPlan();
  }

  /// Load saved week plan from database
  Future<void> _loadWeekPlan() async {
    try {
      final savedPlan = await _dbService.loadWeekPlan();
      
      // Load full recipe objects for each saved recipe ID
      for (var day in savedPlan.keys) {
        for (var meal in savedPlan[day]!.keys) {
          final recipeId = savedPlan[day]![meal];
          if (recipeId != null && recipeId.isNotEmpty) {
            final recipe = await _dbService.getRecipeById(recipeId);
            if (recipe != null && mounted) {
              setState(() {
                _weekPlan[day]![meal] = recipe;
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }

  /// Save week plan to database
  Future<void> _saveWeekPlan() async {
    try {
      // transform Map<String, Map<String, Recipe?>> to Map<String, Map<String, String?>>
      final Map<String, Map<String, String?>> weekPlanIds = _weekPlan.map(
        (day, meals) => MapEntry(
          day,
          meals.map((meal, recipe) => MapEntry(meal, recipe?.id)),
        ),
      );

      await _dbService.saveWeekPlan(weekPlanIds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wochenplan erfolgreich gespeichert!'),
            backgroundColor: Color(0xFFFF5722),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoadingRecipes = true);
    try {
      final recipes = await _dbService.fetchAllRecipes(filter: RecipeFilter.all);
      if (mounted) {
        setState(() {
          _allRecipes = recipes;
          _isLoadingRecipes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRecipes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }

  void _selectRecipe(String day, String meal) async {
    final selectedRecipe = await showDialog<Recipe>(
      context: context,
      builder: (context) => _RecipeSelectionDialog(
        recipes: _allRecipes,
        mealTitle: '$meal für $day',
      ),
    );

    if (selectedRecipe != null) {
      setState(() {
        _weekPlan[day]![meal] = selectedRecipe;
      });
    }
  }

  void _removeRecipe(String day, String meal) {
    setState(() {
      _weekPlan[day]![meal] = null;
    });
  }

  void _generateShoppingList() {
    // Collecter toutes les recettes sélectionnées
    final selectedRecipes = <Recipe>[];
    for (var day in _weekDays) {
      for (var meal in _meals) {
        final recipe = _weekPlan[day]![meal];
        if (recipe != null) {
          selectedRecipes.add(recipe);
        }
      }
    }

    if (selectedRecipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte wähle zuerst einige Rezepte aus'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Générer la liste de courses basée sur les recettes sélectionnées
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Einkaufsliste für ${selectedRecipes.length} Rezepte wird erstellt...'),
        backgroundColor: const Color(0xFFFF5722),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Wochenplan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFFFF5722),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingRecipes
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bouton "Einkaufsliste erstellen" en haut
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _generateShoppingList,
                    icon: const Icon(Icons.shopping_cart, size: 20),
                    label: const Text(
                      'Einkaufsliste erstellen',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                // Liste des jours avec leurs repas
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _weekDays.length,
                    itemBuilder: (context, dayIndex) {
                      final day = _weekDays[dayIndex];
                      return _buildDayCard(day);
                    },
                  ),
                ),

                // Bouton "Speichern" en bas
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        child: const Text('Abbrechen', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _saveWeekPlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Speichern',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDayCard(String day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom du jour
          Text(
            day,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Liste des repas
          ..._meals.map((meal) => _buildMealRow(day, meal)),
        ],
      ),
    );
  }

  Widget _buildMealRow(String day, String meal) {
    final selectedRecipe = _weekPlan[day]?[meal];
    final bool hasRecipe = selectedRecipe != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meal,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _selectRecipe(day, meal),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: hasRecipe ? const Color(0xFFFF5722).withOpacity(0.1) : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasRecipe ? const Color(0xFFFF5722).withOpacity(0.3) : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  if (hasRecipe) ...[
                    const Icon(
                      Icons.restaurant,
                      size: 18,
                      color: Color(0xFFFF5722),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      hasRecipe ? selectedRecipe.title : 'Rezept wählen',
                      style: TextStyle(
                        fontSize: 14,
                        color: hasRecipe ? Colors.black87 : Colors.grey[500],
                        fontWeight: hasRecipe ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (hasRecipe)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: Colors.grey[600],
                      onPressed: () => _removeRecipe(day, meal),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog pour sélectionner une recette avec recherche
class _RecipeSelectionDialog extends StatefulWidget {
  final List<Recipe> recipes;
  final String mealTitle;

  const _RecipeSelectionDialog({
    required this.recipes,
    required this.mealTitle,
  });

  @override
  State<_RecipeSelectionDialog> createState() => _RecipeSelectionDialogState();
}

class _RecipeSelectionDialogState extends State<_RecipeSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Recipe> _filteredRecipes = [];

  @override
  void initState() {
    super.initState();
    _filteredRecipes = widget.recipes;
    _searchController.addListener(_filterRecipes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRecipes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRecipes = widget.recipes;
      } else {
        _filteredRecipes = widget.recipes.where((recipe) {
          return recipe.title.toLowerCase().contains(query) ||
              recipe.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.mealTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rezept suchen...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5722)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Recipe Count
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredRecipes.length} Rezepte gefunden',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Recipe List
            Expanded(
              child: _filteredRecipes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Keine Rezepte gefunden',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _filteredRecipes[index];
                        return _buildRecipeListItem(recipe);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeListItem(Recipe recipe) {
    return InkWell(
      onTap: () => Navigator.pop(context, recipe),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                  ? Image.network(
                      recipe.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.durationMinutes} Min',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.restaurant_menu, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.servings} Portionen',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (recipe.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: recipe.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFFF5722),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Arrow
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}