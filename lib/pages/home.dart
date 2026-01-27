import 'package:flutter/material.dart';
import 'package:kochrezepte_app/pages/Feature_extends/weeklyplan_page.dart';
import 'package:kochrezepte_app/pages/Feature_extends/buy_list_page.dart';
import '../models/recipe.dart';
import '../supabase/database_service.dart';
import '../widgets/recipe_card.dart';
import 'recipe/recipe_form_page.dart';
import 'recipe/recipe_detail_page.dart';
import 'profile_page.dart';
import '../supabase/auth_service.dart';
import 'Login_signUp/login_page.dart';
import '../widgets/searchbar.dart';
import '../widgets/filter_bottom_sheet.dart';

class RecipeHomePage extends StatefulWidget {
  const RecipeHomePage({super.key});

  @override
  State<RecipeHomePage> createState() => _RecipeHomePageState();
}

class _RecipeHomePageState extends State<RecipeHomePage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  List<String> _selectedTags = [];
  String? _selectedTime;

  List<Recipe> _recipes = [];
  bool _isLoading = true;
  Set<String> _favoriteIds = {};
  RecipeFilter _currentFilter = RecipeFilter.all;
  MealType? _selectedMealType;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecipes(filter: _currentFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onToggleFavorite(Recipe recipe) async {
    final id = recipe.id;
    if (id == null || id.isEmpty) return;

    final isFav = _favoriteIds.contains(id);
    setState(() {
      if (isFav) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });

    try {
      await _dbService.toggleFavorite(id);
    } catch (e) {
      setState(() {
        if (isFav) {
          _favoriteIds.add(id);
        } else {
          _favoriteIds.remove(id);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _loadRecipes({required RecipeFilter filter}) async {
    setState(() => _isLoading = true);

    try {
      final recipes = await _dbService.fetchAllRecipes(filter: filter);
      final favoriteIds = await _dbService.fetchUserFavorites();

      if (mounted) {
        setState(() {
          _recipes = recipes;
          _favoriteIds = favoriteIds;
          _isLoading = false;
          _currentFilter = filter;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Laden: $e')));
      }
    }
  }

  void _onFilterSelected(RecipeFilter filter) {
    if (filter != _currentFilter) {
      _loadRecipes(filter: filter);
    }
  }

  Future<void> _navigateToCreateRecipe() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecipeFormPage()),
    );
    if (result == true) {
      _loadRecipes(filter: _currentFilter);
    }
  }

  void _applyFilters() {
    setState(() {});
  }

  List<Recipe> _getFilteredRecipes() {
    List<Recipe> filtered = List.from(_recipes);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();

      // 1. FILTRER : Chercher dans titre, description ET ingrédients
      filtered = filtered.where((recipe) {
        final titleMatch = recipe.title.toLowerCase().contains(query);
        final descMatch =
            recipe.description?.toLowerCase().contains(query) ?? false;

        // Chercher dans les ingrédients
        final ingredientsMatch = recipe.ingredients.any(
          (ing) => ing.name.toLowerCase().contains(query),
        );

        return titleMatch || descMatch || ingredientsMatch;
      }).toList();

      // 2. TRIER par PERTINENCE (priorité : titre > ingrédients > description)
      filtered.sort((a, b) {
        final titleA = a.title.toLowerCase();
        final titleB = b.title.toLowerCase();

        // Priorité 1 : Titre exact
        if (titleA == query && titleB != query) return -1;
        if (titleA != query && titleB == query) return 1;

        // Priorité 2 : Titre contient la recherche
        final titleMatchA = titleA.contains(query);
        final titleMatchB = titleB.contains(query);
        if (titleMatchA && !titleMatchB) return -1;
        if (!titleMatchA && titleMatchB) return 1;

        // Priorité 3 : Ingrédients contiennent la recherche
        final ingMatchA = a.ingredients.any(
          (ing) => ing.name.toLowerCase().contains(query),
        );
        final ingMatchB = b.ingredients.any(
          (ing) => ing.name.toLowerCase().contains(query),
        );
        if (ingMatchA && !ingMatchB) return -1;
        if (!ingMatchA && ingMatchB) return 1;

        // Priorité 4 : Description contient la recherche
        final descMatchA =
            a.description?.toLowerCase().contains(query) ?? false;
        final descMatchB =
            b.description?.toLowerCase().contains(query) ?? false;
        if (descMatchA && !descMatchB) return -1;
        if (!descMatchA && descMatchB) return 1;

        // Priorité 5 : Ordre alphabétique
        return titleA.compareTo(titleB);
      });
    }

    // 3. FILTRER par TEMPS
    if (_selectedTime != null) {
      filtered = filtered.where((recipe) {
        final duration = recipe.durationMinutes;

        switch (_selectedTime) {
          case '0-20':
            return duration >= 0 && duration <= 20;
          case '20-30':
            return duration >= 20 && duration <= 30;
          case '30-45':
            return duration >= 30 && duration <= 45;
          case '45-60':
            return duration >= 45 && duration <= 60;
          case '60-90':
            return duration >= 60 && duration <= 90;
          case '90+':
            return duration >= 90;
          default:
            return true;
        }
      }).toList();
      filtered.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
    }
    if (_selectedMealType != null) {
      filtered = filtered.where((recipe) {
        return recipe.mealType == _selectedMealType;
      }).toList();
    }
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((recipe) {
        return _selectedTags.every(
          (selectedTag) => recipe.tags.any(
            (recipeTag) => recipeTag.toLowerCase() == selectedTag.toLowerCase(),
          ),
        );
      }).toList();
    }
    return filtered;
  }

  Widget _buildSimpleFilterChip(
    String label,
    RecipeFilter filter,
    IconData icon,
  ) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () => _onFilterSelected(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFFE65100) : Colors.grey[600],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFFE65100) : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 30,
              color: isSelected ? const Color(0xFFE65100) : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        selectedTags: _selectedTags,
        selectedTime: _selectedTime,
        selectedMealType: _selectedMealType,
        onApply: (tags, selectedTime, selectedMealType) {
          setState(() {
            _selectedTags = tags;
            _selectedTime = selectedTime;
            _selectedMealType = selectedMealType;
            _applyFilters();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.restaurant_menu, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Rezepte',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await _authService.signOut();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFE65100),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: RecipeSearchBar(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          Container(
            height: 50,
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSimpleFilterChip(
                  'Alle',
                  RecipeFilter.all,
                  Icons.grid_view,
                ),
                _buildSimpleFilterChip(
                  'Neu',
                  RecipeFilter.newest,
                  Icons.fiber_new,
                ),
                _buildSimpleFilterChip(
                  'Beliebt',
                  RecipeFilter.popular,
                  Icons.trending_up,
                ),
                _buildSimpleFilterChip(
                  'Gespeichert',
                  RecipeFilter.favorite,
                  Icons.bookmark,
                ),
                _buildSimpleFilterChip(
                  'Meine',
                  RecipeFilter.mine,
                  Icons.person,
                ),
              ],
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showFilterBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFE65100),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 18,
                          color: Color(0xFFE65100),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Filter',
                          style: TextStyle(
                            color: Color(0xFFE65100),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                if (_selectedTags.isNotEmpty ||
                    _selectedTime != null ||
                    _selectedMealType != null)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedMealType != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text(
                                  _getMealTypeLabel(_selectedMealType!),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _selectedMealType = null;
                                    _applyFilters();
                                  });
                                },
                                backgroundColor: const Color(
                                  0xFFE65100,
                                ).withValues(alpha: 0.15),
                                labelStyle: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFE65100),
                                  fontWeight: FontWeight.w500,
                                ),
                                deleteIconColor: const Color(0xFFE65100),
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ..._selectedTags.map(
                            (tag) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text(tag),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _selectedTags.remove(tag);
                                    _applyFilters();
                                  });
                                },
                                backgroundColor: const Color(
                                  0xFFE65100,
                                ).withOpacity(0.15),
                                labelStyle: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFE65100),
                                  fontWeight: FontWeight.w500,
                                ),
                                deleteIconColor: const Color(0xFFE65100),
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),

                          if (_selectedTime != null)
                            Chip(
                              label: Text('$_selectedTime Min'),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _selectedTime = null;
                                  _applyFilters();
                                });
                              },
                              backgroundColor: const Color(
                                0xFFE65100,
                              ).withOpacity(0.15),
                              labelStyle: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.w500,
                              ),
                              deleteIconColor: const Color(0xFFE65100),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredRecipes().isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () => _loadRecipes(filter: _currentFilter),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 1;
                        final filteredRecipes = _getFilteredRecipes();
                        if (constraints.maxWidth > 1200) {
                          crossAxisCount = 3;
                        } else if (constraints.maxWidth > 700) {
                          crossAxisCount = 2;
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: crossAxisCount == 1
                                    ? 1.1
                                    : 0.99,
                              ),
                          itemCount: filteredRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = filteredRecipes[index];
                            final id = recipe.id ?? '';

                            return RecipeCard(
                              recipe: recipe,
                              onTap: () async {
                                final changed = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RecipeDetailScreen(recipe: recipe),
                                  ),
                                );
                                if (changed == true) {
                                  _loadRecipes(filter: _currentFilter);
                                }
                              },
                              isFavorite:
                                  id.isNotEmpty && _favoriteIds.contains(id),
                              onFavoriteToggle: () => _onToggleFavorite(recipe),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateRecipe,
        backgroundColor: const Color(0xFFFF5722),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFFE65100),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Rezepte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Wochenplan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Einkauf',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeeklyplanPage()),
            );
          } else if (index == 2) {
            // Navigator to Einkauf
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BuyListPage()),
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasActiveFilters =
        _selectedTags.isNotEmpty ||
        _selectedTime != null ||
        _selectedMealType != null;
    String message = 'No recipes found.';
    if (_searchQuery.isNotEmpty) {
      message = 'Keine Rezepte für "$_searchQuery" gefunden.';
    }
    if (hasActiveFilters) {
      message = 'No recipes match your filters.';
    } else if (_currentFilter == RecipeFilter.mine) {
      message = 'You have not created any recipes yet.';
    } else if (_currentFilter == RecipeFilter.favorite) {
      message = 'You have not saved any recipes as favorites.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_currentFilter == RecipeFilter.all)
            Text(
              'Tap + to add a recipe',
              style: TextStyle(color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }

  String _getMealTypeLabel(MealType type) {
    switch (type) {
      case MealType.fruehstueck:
        return 'Frühstück';
      case MealType.vorspeise:
        return 'Vorspeise';
      case MealType.hauptgericht:
        return 'Hauptgericht';
      case MealType.beilage:
        return 'Beilage';
      case MealType.dessert:
        return 'Dessert';
      case MealType.snack:
        return 'Snack';
    }
  }
}
