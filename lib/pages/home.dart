import 'package:flutter/material.dart';
import 'package:kochrezepte_app/pages/weeklyplan/weeklyplan_page.dart';

import '../models/recipe.dart';
import '../supabase/database_service.dart';
import '../supabase/auth_service.dart';

import '../widgets/recipe_card.dart';
import '../widgets/searchbar.dart';
import '../widgets/filter_bottom_sheet.dart';

import 'recipe/recipe_form_page.dart';
import 'recipe/recipe_detail_page.dart';
import 'profile_page.dart';
import 'Login_signUp/login_page.dart';

class RecipeHomePage extends StatefulWidget {
  const RecipeHomePage({super.key});

  @override
  State<RecipeHomePage> createState() => _RecipeHomePageState();
}

class _RecipeHomePageState extends State<RecipeHomePage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  // ---------------- DATA ----------------
  List<Recipe> _recipes = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = true;

  RecipeFilter _currentFilter = RecipeFilter.all;

  // ---------------- SEARCH & FILTER ----------------
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<String> _selectedTags = [];
  String? _selectedTime;
  MealType? _selectedMealType;

  // ---------------- INIT ----------------
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

  // ---------------- LOGOUT ----------------
  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abmelden?'),
        content: const Text('Möchtest du dich wirklich abmelden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await _authService.signOut();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du wurdest abgemeldet.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  // ---------------- DATA ----------------
  Future<void> _loadRecipes({required RecipeFilter filter}) async {
    setState(() => _isLoading = true);

    try {
      final recipes = await _dbService.fetchAllRecipes(filter: filter);
      final favorites = await _dbService.fetchUserFavorites();

      if (!mounted) return;

      setState(() {
        _recipes = recipes;
        _favoriteIds = favorites;
        _currentFilter = filter;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler: $e')));
    }
  }

  Future<void> _onToggleFavorite(Recipe recipe) async {
    final id = recipe.id;
    if (id == null || id.isEmpty) return;

    final isFav = _favoriteIds.contains(id);

    setState(() {
      isFav ? _favoriteIds.remove(id) : _favoriteIds.add(id);
    });

    try {
      await _dbService.toggleFavorite(id);
    } catch (e) {
      setState(() {
        isFav ? _favoriteIds.add(id) : _favoriteIds.remove(id);
      });
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

  // ---------------- FILTER LOGIC ----------------
  List<Recipe> _getFilteredRecipes() {
    List<Recipe> filtered = List.from(_recipes);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered =
          filtered.where((r) => r.title.toLowerCase().contains(q)).toList();
    }

    if (_selectedTags.isNotEmpty) {
      filtered = filtered
          .where((r) => _selectedTags.any((t) => r.tags.contains(t)))
          .toList();
    }

    if (_selectedMealType != null) {
      filtered =
          filtered.where((r) => r.mealType == _selectedMealType).toList();
    }

    if (_selectedTime != null) {
      filtered = filtered.where((r) {
        final d = r.durationMinutes;
        switch (_selectedTime) {
          case '0-20':
            return d <= 20;
          case '20-30':
            return d > 20 && d <= 30;
          case '30-45':
            return d > 30 && d <= 45;
          case '45-60':
            return d > 45 && d <= 60;
          case '60-90':
            return d > 60 && d <= 90;
          case '90+':
            return d >= 90;
          default:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final filteredRecipes = _getFilteredRecipes();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        title: const Text(
          'Rezepte',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Container(
            color: const Color(0xFFE65100),
            padding: const EdgeInsets.all(16),
            child: RecipeSearchBar(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // FILTER TABS
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterTab('Alle', RecipeFilter.all),
                _buildFilterTab('Neu', RecipeFilter.newest),
                _buildFilterTab('Beliebt', RecipeFilter.popular),
                _buildFilterTab('Gespeichert', RecipeFilter.favorite),
                _buildFilterTab('Meine', RecipeFilter.mine),
              ],
            ),
          ),

          // LIST
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredRecipes.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () =>
                            _loadRecipes(filter: _currentFilter),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.1,
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
                                    builder: (_) => RecipeDetailScreen(
                                      recipe: recipe,
                                    ),
                                  ),
                                );
                                if (changed == true) {
                                  _loadRecipes(filter: _currentFilter);
                                }
                              },
                              isFavorite: _favoriteIds.contains(id),
                              onFavoriteToggle: () =>
                                  _onToggleFavorite(recipe),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateRecipe,
        backgroundColor: const Color(0xFFE65100),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFFE65100),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Rezepte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Wochenplan',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeeklyplanPage()),
            );
          }
        },
      ),
    );
  }

  // ---------------- HELPERS ----------------
  Widget _buildFilterTab(String label, RecipeFilter filter) {
    final isSelected = _currentFilter == filter;

    return GestureDetector(
      onTap: () => _loadRecipes(filter: filter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              color:
                  isSelected ? const Color(0xFFE65100) : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 30,
            color:
                isSelected ? const Color(0xFFE65100) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Keine Rezepte gefunden',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }
}
