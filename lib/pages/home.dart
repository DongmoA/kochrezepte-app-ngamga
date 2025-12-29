import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../supabase/database_service.dart';
import '../widgets/recipe_card.dart';
import 'recipe/recipe_form_page.dart';
import 'recipe/recipe_detail_page.dart';
import 'package:kochrezepte_app/pages/profile_page.dart';
import 'package:kochrezepte_app/supabase/auth_service.dart';
import 'package:kochrezepte_app/pages/Login_signUp/login_page.dart';


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
  // 1. Store the list of favorite Recipe IDs locally
  Set<String> _favoriteIds = {};
  
  //  State variable to track the currently selected filter
  RecipeFilter _currentFilter = RecipeFilter.all; 

  // Mapping des filtres pour l'affichage
  static const Map<RecipeFilter, String> _filterLabels = {
    RecipeFilter.all: 'Alle',
    RecipeFilter.favorite: 'Gespeichert',
    RecipeFilter.newest: 'Neu',
    RecipeFilter.popular: 'Beliebt',
    RecipeFilter.mine: 'Meine',
  };


  @override
  void initState() {
    super.initState();
    // Appeler avec le filtre par défaut
    _loadRecipes(filter: _currentFilter);
  }

Future<void> _onToggleFavorite(Recipe recipe) async {
    // Optimistic UI update (update immediately before server response)
    final isFav = _favoriteIds.contains(recipe.id);
    setState(() {
      if (isFav) {
        _favoriteIds.remove(recipe.id);
      } else {
        _favoriteIds.add(recipe.id!);
      }
    });

    try {
      await _dbService.toggleFavorite(recipe.id!);
    } catch (e) {
      // Revert if error
      setState(() {
         if (isFav) _favoriteIds.add(recipe.id!);
         else  _favoriteIds.remove(recipe.id);
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  /// Fetches recipes based on the currently selected filter.
  Future<void> _loadRecipes({required RecipeFilter filter}) async {
    if (filter == _currentFilter && !_isLoading && _recipes.isNotEmpty) {
      // Optimization: avoid reloading if the filter hasn't changed and data is present
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Fetch both recipes and user favorites in parallel
      final recipes = await _dbService.fetchAllRecipes(filter: filter);
      final favoriteIds = await _dbService.fetchUserFavorites();
      
      if (mounted) {
        setState(() {
          _recipes = recipes;
          _favoriteIds = favoriteIds; // Update favorite IDs
          _isLoading = false;
          _currentFilter = filter; // Update the filter state upon successful load
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

  /// Handles the selection of a new filter
  void _onFilterSelected(RecipeFilter filter) {
    if (filter != _currentFilter) {
      _loadRecipes(filter: filter);
    }
  }

  void _navigateToCreateRecipe() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecipeFormPage()),
    );
    
    // Reload recipes with the current filter if a recipe was added
    if (result == true) {
      _loadRecipes(filter: _currentFilter);
    }
  }

  /// NEW: Widget to build the horizontal filter bar
  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _filterLabels.length,
        itemBuilder: (context, index) {
          final filter = _filterLabels.keys.elementAt(index);
          final label = _filterLabels[filter]!;
          final isSelected = filter == _currentFilter;

          return ActionChip(
            label: Text(label),
            // Style the chip to show selection
            backgroundColor: isSelected ? Colors.orange : Colors.grey[200],
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            onPressed: () => _onFilterSelected(filter),
          );
        },
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
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
        ),
        IconButton(
  icon: const Icon(Icons.logout),
  onPressed: () async {
    try {
      await _authService.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      print('Erreur : $e');
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
                      onRefresh: () => _loadRecipes(filter: _currentFilter),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _recipes[index];
                          
                          return RecipeCard(
                            recipe: recipe,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecipeDetailScreen(recipe: recipe),
                                ),
                              );
                            },
                            isFavorite: _favoriteIds.contains(recipe.id),
                            onFavoriteToggle: () => _onToggleFavorite(recipe),
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

  /// Displays a friendly message when the list is empty.
  Widget _buildEmptyState() {
    // We can also add context to the empty state based on the filter
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
              'Tap + to add your first recipe',
              style: TextStyle(color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }
}