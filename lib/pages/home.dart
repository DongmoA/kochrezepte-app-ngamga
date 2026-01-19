import 'package:flutter/material.dart';
import 'package:kochrezepte_app/pages/weeklyplan/weeklyplan_page.dart';
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
  MealType? _selectedMealType;

  List<Recipe> _recipes = [];
  bool _isLoading = true;
  Set<String> _favoriteIds = {};
  RecipeFilter _currentFilter = RecipeFilter.all;

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

  // --------------------------------------------------
  // LOGOUT CONFIRMATION
  // --------------------------------------------------
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
          .showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  // --------------------------------------------------
  // DATA
  // --------------------------------------------------
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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler beim Laden: $e')));
      }
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

  // --------------------------------------------------
  // FILTERS
  // --------------------------------------------------
  List<Recipe> _getFilteredRecipes() {
    List<Recipe> filtered = List.from(_recipes);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((r) => r.title.toLowerCase().contains(q))
          .toList();
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

    return filtered;
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
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
            onPressed: _confirmLogout, // ✅ confirmation ici
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _loadRecipes(filter: _currentFilter),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _getFilteredRecipes().length,
                    itemBuilder: (context, index) {
                      final recipe = _getFilteredRecipes()[index];
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
                        onFavoriteToggle: () =>
                            _onToggleFavorite(recipe),
                      );
                    },
                  ),
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

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Keine Rezepte gefunden',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }
}
