import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../supabase/database_service.dart';
import '../widgets/recipe_card.dart';
import 'recipe/recipe_form_page.dart';
import 'recipe/recipe_detail_page.dart';
import 'profile_page.dart';
import '../supabase/auth_service.dart';
import 'Login_signUp/login_page.dart';

class RecipeHomePage extends StatefulWidget {
  const RecipeHomePage({super.key});

  @override
  State<RecipeHomePage> createState() => _RecipeHomePageState();
}

class _RecipeHomePageState extends State<RecipeHomePage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  List<Recipe> _recipes = [];
  bool _isLoading = true;
  Set<String> _favoriteIds = {};
  RecipeFilter _currentFilter = RecipeFilter.all;

  static const Map<RecipeFilter, String> _filterLabels = {
    RecipeFilter.all: 'Alle',
    RecipeFilter.favorite: 'Gespeichert',
    RecipeFilter.newest: 'Neu',
    RecipeFilter.popular: 'Beliebt',
    RecipeFilter.mine: 'Meine',
  };

  static const Map<RecipeFilter, IconData> _filterIcons = {
    RecipeFilter.all: Icons.grid_view,
    RecipeFilter.favorite: Icons.favorite,
    RecipeFilter.newest: Icons.fiber_new,
    RecipeFilter.popular: Icons.trending_up,
    RecipeFilter.mine: Icons.person,
  };

  @override
  void initState() {
    super.initState();
    _loadRecipes(filter: _currentFilter);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
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

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: _filterLabels.keys.map((filter) {
          final label = _filterLabels[filter]!;
          final icon = _filterIcons[filter]!;
          final isSelected = filter == _currentFilter;

          return Expanded(
            child: InkWell(
              onTap: () => _onFilterSelected(filter),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: Colors.black87),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 3,
                    width: 100,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.grey : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipes'),
        backgroundColor: Colors.orange,
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
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Erreur: $e")));
                }
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: _buildFilterChips(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _recipes.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () =>
                            _loadRecipes(filter: _currentFilter),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 1;
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
                                childAspectRatio:
                                    crossAxisCount == 1 ? 1.1 : 0.85,
                              ),
                              itemCount: _recipes.length,
                              itemBuilder: (context, index) {
                                final recipe = _recipes[index];
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
                                      _loadRecipes(
                                          filter: _currentFilter);
                                    }
                                  },
                                  isFavorite:
                                      id.isNotEmpty &&
                                          _favoriteIds.contains(id),
                                  onFavoriteToggle: () =>
                                      _onToggleFavorite(recipe),
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
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'No recipes found.';
    if (_currentFilter == RecipeFilter.mine) {
      message = 'You have not created any recipes yet.';
    } else if (_currentFilter == RecipeFilter.favorite) {
      message = 'You have not saved any recipes as favorites.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu,
              size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_currentFilter == RecipeFilter.all)
            Text(
              'Tap + to add your first recipe',
              style: TextStyle(color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }
}
