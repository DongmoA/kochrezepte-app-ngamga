import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../supabase/database_service.dart';
import 'package:intl/intl.dart';
import '../Recipe/recipe_detail_page.dart';

class WeeklyplanPage extends StatefulWidget {
  const WeeklyplanPage({super.key});

  @override
  State<WeeklyplanPage> createState() => _WeeklyplanPageState();
}

class _WeeklyplanPageState extends State<WeeklyplanPage> {
  final DatabaseService _dbService = DatabaseService();

  final List<String> _weekDays = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];

  final List<String> _weekDaysShort = [
    'Mo',
    'Di',
    'Mi',
    'Do',
    'Fr',
    'Sa',
    'So',
  ];

  final List<String> _meals = ['Frühstück', 'Mittagessen', 'Abendessen'];

  DateTime _currentWeekStart = DateTime.now();
  final Map<String, Map<String, Recipe?>> _weekPlan = {};

  // NEU: Tracking für ungespeicherte Änderungen
  bool _hasUnsavedChanges = false;
  Map<String, Map<String, Recipe?>> _originalWeekPlan = {};

  List<Recipe> _allRecipes = [];
  bool _isLoadingRecipes = false;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(DateTime.now());
    for (var day in _weekDays) {
      _weekPlan[day] = {};
      for (var meal in _meals) {
        _weekPlan[day]![meal] = null;
      }
    }
    _loadRecipes();
    _loadWeekPlan();
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  void _navigateWeek(bool forward) async {
    // Prüfe ob es ungespeicherte Änderungen gibt
    if (_hasUnsavedChanges) {
      final shouldDiscard = await _showDiscardDialog();
      if (!shouldDiscard) return;
    }

    setState(() {
      _currentWeekStart = _currentWeekStart.add(
        Duration(days: forward ? 7 : -7),
      );
      _hasUnsavedChanges = false;
    });

    _clearAndReloadWeekPlan();
  }

  void _goToCurrentWeek() async {
    // Prüfe ob es ungespeicherte Änderungen gibt
    if (_hasUnsavedChanges) {
      final shouldDiscard = await _showDiscardDialog();
      if (!shouldDiscard) return;
    }

    setState(() {
      _currentWeekStart = _getWeekStart(DateTime.now());
      _hasUnsavedChanges = false;
    });

    _clearAndReloadWeekPlan();
  }

  void _clearAndReloadWeekPlan() {
    for (var day in _weekDays) {
      for (var meal in _meals) {
        _weekPlan[day]![meal] = null;
      }
    }

    _loadWeekPlan();
  }

  String _getWeekRangeText() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final months = [
      '',
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];

    final startDay = _currentWeekStart.day;
    final startMonth = months[_currentWeekStart.month];
    final endDay = weekEnd.day;
    final endMonth = months[weekEnd.month];

    if (_currentWeekStart.month == weekEnd.month) {
      return '$startDay. - $endDay. $endMonth';
    } else {
      return '$startDay. $startMonth - $endDay. $endMonth';
    }
  }

  bool _isCurrentWeek() {
    final today = DateTime.now();
    final thisWeekStart = _getWeekStart(today);
    return _currentWeekStart.year == thisWeekStart.year &&
        _currentWeekStart.month == thisWeekStart.month &&
        _currentWeekStart.day == thisWeekStart.day;
  }

  DateTime _getDateForDayIndex(int index) {
    return _currentWeekStart.add(Duration(days: index));
  }

  bool _isToday(int dayIndex) {
    final date = _getDateForDayIndex(dayIndex);
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  Future<void> _loadWeekPlan() async {
    try {
      final savedPlan = await _dbService.loadWeekPlan();

      for (var dayIndex = 0; dayIndex < _weekDays.length; dayIndex++) {
        final day = _weekDays[dayIndex];
        final date = _getDateForDayIndex(dayIndex);
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        if (savedPlan.containsKey(dateKey)) {
          for (var meal in savedPlan[dateKey]!.keys) {
            final recipeId = savedPlan[dateKey]![meal];
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
      }

      // NEU: Speichere den ursprünglichen Zustand
      _saveOriginalState();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Laden: $e')));
      }
    }
  }

  // NEU: Speichere den ursprünglichen Zustand für Vergleich
  void _saveOriginalState() {
    _originalWeekPlan = {};
    for (var day in _weekDays) {
      _originalWeekPlan[day] = {};
      for (var meal in _meals) {
        _originalWeekPlan[day]![meal] = _weekPlan[day]![meal];
      }
    }
    _hasUnsavedChanges = false;
  }

  // NEU: Prüfe ob es Änderungen gibt
  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  // NEU: Dialog für ungespeicherte Änderungen
  Future<bool> _showDiscardDialog() async {
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Änderungen verwerfen?'),
        content: const Text(
          'Du hast ungespeicherte Änderungen am Wochenplan. Möchtest du die Seite wirklich verlassen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verwerfen'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  // NEU: Behandle Back-Button
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    return await _showDiscardDialog();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoadingRecipes = true);
    try {
      final recipes = await _dbService.fetchAllRecipes(
        filter: RecipeFilter.all,
      );
      if (mounted) {
        setState(() {
          _allRecipes = recipes;
          _isLoadingRecipes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRecipes = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Laden: $e')));
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
        _markAsChanged(); // NEU: Markiere als geändert
      });
    }
  }

  void _removeRecipe(String day, String meal) {
    setState(() {
      _weekPlan[day]![meal] = null;
      _markAsChanged(); // NEU: Markiere als geändert
    });
  }

  Future<void> _saveWeekPlan() async {
    try {
      // Lade zuerst alle existierenden Daten
      final savedPlan = await _dbService.loadWeekPlan();

      // Aktualisiere nur die aktuelle Woche
      for (var dayIndex = 0; dayIndex < _weekDays.length; dayIndex++) {
        final day = _weekDays[dayIndex];
        final date = _getDateForDayIndex(dayIndex);
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        // Erstelle oder aktualisiere den Eintrag für dieses Datum
        savedPlan[dateKey] = _weekPlan[day]!.map(
          (meal, recipe) => MapEntry(meal, recipe?.id),
        );
      }

      // Speichere alles zurück (mit alten + neuen Daten)
      await _dbService.saveWeekPlan(savedPlan);

      if (mounted) {
        // NEU: Aktualisiere den ursprünglichen Zustand und setze Flag zurück
        _saveOriginalState();

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

  void _generateShoppingList() {
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Einkaufsliste für ${selectedRecipes.length} Rezepte wird erstellt...',
        ),
        backgroundColor: const Color(0xFFFF5722),
      ),
    );
  }

  Recipe? _getFirstRecipeOfDay(String day) {
    for (var meal in _meals) {
      final recipe = _weekPlan[day]?[meal];
      if (recipe != null) return recipe;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // NEU: Verwende PopScope für Back-Button Handling
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'Wochenplan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFFF5722),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              // NEU: Prüfe auf ungespeicherte Änderungen
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: _generateShoppingList,
              tooltip: 'Einkaufsliste',
            ),
            if (!_isCurrentWeek())
              IconButton(
                icon: const Icon(Icons.today, color: Colors.white),
                onPressed: _goToCurrentWeek,
                tooltip: 'Heute',
              ),
          ],
        ),
        body: _isLoadingRecipes
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildWeekHeader(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _weekDays.length,
                      itemBuilder: (context, index) {
                        return _buildDayCard(index);
                      },
                    ),
                  ),
                  _buildActionButtons(),
                ],
              ),
      ),
    );
  }

  Widget _buildWeekHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isCurrentWeek() ? 'Diese Woche' : 'Woche',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getWeekRangeText(),
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _navigateWeek(false),
                    color: const Color(0xFFFF5722),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _navigateWeek(true),
                    color: const Color(0xFFFF5722),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(int dayIndex) {
    final day = _weekDays[dayIndex];
    final dayShort = _weekDaysShort[dayIndex];
    final date = _getDateForDayIndex(dayIndex);
    final isToday = _isToday(dayIndex);
    final firstRecipe = _getFirstRecipeOfDay(day);
    final hasAnyRecipe = _meals.any((meal) => _weekPlan[day]?[meal] != null);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              if (hasAnyRecipe && firstRecipe != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(recipe: firstRecipe),
                  ),
                );
              } else {
                _selectRecipe(day, _meals[0]);
              }
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFFFF5722)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayShort,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isToday ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isToday ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  if (firstRecipe != null && firstRecipe.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        firstRecipe.imageUrl!,
                        width: 100,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  Expanded(
                    child: firstRecipe != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                firstRecipe.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getMealNameForRecipe(day, firstRecipe),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Rezepte hinzufügen',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                  ),

                  if (hasAnyRecipe)
                    IconButton(
                      icon: const Icon(Icons.shopping_basket),
                      color: const Color(0xFFFF5722),
                      onPressed: () {},
                    ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: _meals.map((meal) => _buildMealRow(day, meal)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getMealNameForRecipe(String day, Recipe recipe) {
    for (var meal in _meals) {
      if (_weekPlan[day]?[meal]?.id == recipe.id) {
        return meal;
      }
    }
    return '';
  }

  Widget _buildMealRow(String day, String meal) {
    final selectedRecipe = _weekPlan[day]?[meal];
    final bool hasRecipe = selectedRecipe != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          if (hasRecipe) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(recipe: selectedRecipe),
              ),
            );
          } else {
            _selectRecipe(day, meal);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasRecipe
                ? Colors.white
                : const Color(0xFFFF5722).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasRecipe
                  ? Colors.grey[200]!
                  : const Color(0xFFFF5722).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              if (hasRecipe) ...[
                if (selectedRecipe.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      selectedRecipe.imageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            size: 20,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(width: 12),
              ],

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasRecipe ? selectedRecipe.title : 'Rezept hinzufügen',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: hasRecipe
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: hasRecipe
                            ? Colors.black87
                            : const Color(0xFFFF5722),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              if (hasRecipe)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey[600],
                  onPressed: () => _removeRecipe(day, meal),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                Icon(
                  Icons.add_circle_outline,
                  size: 28,
                  color: const Color(0xFFFF5722),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () async {
              // NEU: Prüfe auf ungespeicherte Änderungen
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _saveWeekPlan,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Speichern',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.mealTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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

            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rezept suchen...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5722)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredRecipes.length} Rezepte',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _filteredRecipes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Keine Rezepte gefunden',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                  ? Image.network(
                      recipe.imageUrl!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.durationMinutes} Min',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.restaurant_menu,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.servings} Port.',
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFFF5722),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
