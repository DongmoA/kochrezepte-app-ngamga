import 'package:flutter/material.dart';
import 'package:kochrezepte_app/pages/Recipe/recipe_detail_page.dart';
import '../models/recipe.dart';
import '../supabase/database_service.dart';
import 'recipe/recipe_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dbService = DatabaseService();
  
  // Keys für die Tabs um sie neu zu laden
  final GlobalKey<_AllRecipesTabState> _allRecipesKey = GlobalKey();
  final GlobalKey<_NewRecipesTabState> _newRecipesKey = GlobalKey();
  final GlobalKey<_PopularRecipesTabState> _popularRecipesKey = GlobalKey();
  final GlobalKey<_SavedRecipesTabState> _savedRecipesKey = GlobalKey();
  final GlobalKey<_MyRecipesTabState> _myRecipesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Diese Methode wird aufgerufen wenn IRGENDEIN Button geklickt wird
  void _refreshAllTabs() {
    _allRecipesKey.currentState?._loadRecipes();
    _newRecipesKey.currentState?._loadRecipes();
    _popularRecipesKey.currentState?._loadRecipes();
    _savedRecipesKey.currentState?._loadRecipes();
    _myRecipesKey.currentState?._loadRecipes();
  }

  void _navigateToCreateRecipe() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecipeFormPage()),
    );
    
    if (result == true) {
      _refreshAllTabs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        backgroundColor: Colors.orange,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu, size: 20), text: 'All'),
            Tab(icon: Icon(Icons.schedule, size: 20), text: 'New'),
            Tab(icon: Icon(Icons.favorite, size: 20), text: 'Popular'),
            Tab(icon: Icon(Icons.bookmark, size: 20), text: 'Saved'),
            Tab(icon: Icon(Icons.person, size: 20), text: 'Mine'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllRecipesTab(
            key: _allRecipesKey,
            dbService: _dbService,
            onChanged: _refreshAllTabs,
          ),
          _NewRecipesTab(
            key: _newRecipesKey,
            dbService: _dbService,
            onChanged: _refreshAllTabs,
          ),
          _PopularRecipesTab(
            key: _popularRecipesKey,
            dbService: _dbService,
            onChanged: _refreshAllTabs,
          ),
          _SavedRecipesTab(
            key: _savedRecipesKey,
            dbService: _dbService,
            onChanged: _refreshAllTabs,
          ),
          _MyRecipesTab(
            key: _myRecipesKey,
            dbService: _dbService,
            onChanged: _refreshAllTabs,
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
}

// ==================== TAB 0: ALLE REZEPTE ====================
class _AllRecipesTab extends StatefulWidget {
  final DatabaseService dbService;
  final VoidCallback? onChanged;

  const _AllRecipesTab({
    super.key,
    required this.dbService,
    this.onChanged,
  });

  @override
  State<_AllRecipesTab> createState() => _AllRecipesTabState();
}

class _AllRecipesTabState extends State<_AllRecipesTab> with AutomaticKeepAliveClientMixin {
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final recipes = await widget.dbService.fetchAllRecipes();
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recipes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant_menu,
        title: 'No recipes yet',
        subtitle: 'Create your first recipe with the + button',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecipes,
      child: _RecipeListView(
        recipes: _recipes,
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ==================== TAB 1: NEUE REZEPTE ====================
class _NewRecipesTab extends StatefulWidget {
  final DatabaseService dbService;
  final VoidCallback? onChanged;

  const _NewRecipesTab({
    super.key,
    required this.dbService,
    this.onChanged,
  });

  @override
  State<_NewRecipesTab> createState() => _NewRecipesTabState();
}

class _NewRecipesTabState extends State<_NewRecipesTab> with AutomaticKeepAliveClientMixin {
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final recipes = await widget.dbService.fetchNewRecipes();
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recipes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.auto_awesome,
        title: 'No new recipes',
        subtitle: 'Be the first to create a recipe!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecipes,
      child: _RecipeListView(
        recipes: _recipes, 
        showNewBadge: true,
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ==================== TAB 2: BELIEBTE REZEPTE ====================
class _PopularRecipesTab extends StatefulWidget {
  final DatabaseService dbService;
  final VoidCallback? onChanged;

  const _PopularRecipesTab({
    super.key,
    required this.dbService,
    this.onChanged,
  });

  @override
  State<_PopularRecipesTab> createState() => _PopularRecipesTabState();
}

class _PopularRecipesTabState extends State<_PopularRecipesTab> with AutomaticKeepAliveClientMixin {
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final recipes = await widget.dbService.fetchPopularRecipes();
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recipes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.star_border,
        title: 'No popular recipes',
        subtitle: 'Rate recipes with ⭐ and they will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecipes,
      child: _RecipeListView(
        recipes: _recipes, 
        showRanking: true,
        hideRatingButton: true, // ← NEU: Rating-Button ausblenden im Beliebt-Tab
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ==================== TAB 3: GESPEICHERTE REZEPTE ====================
class _SavedRecipesTab extends StatefulWidget {
  final DatabaseService dbService;
  final VoidCallback? onChanged;

  const _SavedRecipesTab({
    super.key,
    required this.dbService,
    this.onChanged,
  });

  @override
  State<_SavedRecipesTab> createState() => _SavedRecipesTabState();
}

class _SavedRecipesTabState extends State<_SavedRecipesTab> with AutomaticKeepAliveClientMixin {
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final recipes = await widget.dbService.fetchSavedRecipes();
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recipes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border,
        title: 'No saved recipes',
        subtitle: 'Save recipes by tapping the bookmark icon 🔖',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecipes,
      child: _RecipeListView(
        recipes: _recipes,
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ==================== TAB 4: MEINE REZEPTE ====================
class _MyRecipesTab extends StatefulWidget {
  final DatabaseService dbService;
  final VoidCallback? onChanged;

  const _MyRecipesTab({
    super.key,
    required this.dbService,
    this.onChanged,
  });

  @override
  State<_MyRecipesTab> createState() => _MyRecipesTabState();
}

class _MyRecipesTabState extends State<_MyRecipesTab> with AutomaticKeepAliveClientMixin {
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final recipes = await widget.dbService.fetchMyRecipes();
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recipes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant_menu,
        title: 'No recipes yet',
        subtitle: 'Create your first recipe with the + button',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecipes,
      child: _RecipeListView(
        recipes: _recipes,
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ==================== SHARED COMPONENTS ====================

Widget _buildEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _RecipeListView extends StatelessWidget {
  final List<Recipe> recipes;
  final bool showRanking;
  final bool showNewBadge;
  final bool hideRatingButton; // ← NEU: Rating-Button ausblenden
  final VoidCallback? onChanged;

  const _RecipeListView({
    required this.recipes,
    this.showRanking = false,
    this.showNewBadge = false,
    this.hideRatingButton = false, // ← Default: Button wird angezeigt
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        return _RecipeCard(
          recipe: recipes[index],
          ranking: showRanking ? index + 1 : null,
          showNewBadge: showNewBadge,
          hideRatingButton: hideRatingButton, // ← Weitergeben
          onChanged: onChanged,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeDetailPage(recipe: recipes[index]),
              ),
            );
          },
        );
      },
    );
  }
}

class _RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final int? ranking;
  final bool showNewBadge;
  final bool hideRatingButton; // ← NEU
  final VoidCallback onTap;
  final VoidCallback? onChanged;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
    this.ranking,
    this.showNewBadge = false,
    this.hideRatingButton = false, // ← NEU
    this.onChanged,
  });

  @override
  State<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<_RecipeCard> {
  final DatabaseService _dbService = DatabaseService();
  bool _isFavorite = false;
  int? _userRating; // ← Rating statt isPopular
  double _averageRating = 0.0;
  int _totalRatings = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (widget.recipe.id != null && widget.recipe.id!.isNotEmpty) {
      final isFav = await _dbService.isFavorite(widget.recipe.id!);
      final userRating = await _dbService.fetchUserRating(widget.recipe.id!);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _userRating = userRating;
          _averageRating = widget.recipe.averageRating;
          _totalRatings = widget.recipe.totalRatings;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.recipe.id == null || widget.recipe.id!.isEmpty) return;

    try {
      if (_isFavorite) {
        await _dbService.removeFromFavorites(widget.recipe.id!);
        setState(() => _isFavorite = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from saved 🔖'),
              duration: Duration(seconds: 1),
            ),
          );
          widget.onChanged?.call();
        }
      } else {
        await _dbService.addToFavorites(widget.recipe.id!);
        setState(() => _isFavorite = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to saved 🔖'),
              duration: Duration(seconds: 1),
            ),
          );
          widget.onChanged?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  Future<void> _showRatingDialog() async {
    if (widget.recipe.id == null || widget.recipe.id!.isEmpty) return;

    final rating = await showDialog<int>(
      context: context,
      builder: (context) => _RatingDialog(currentRating: _userRating),
    );

    if (rating != null && mounted) {
      try {
        await _dbService.rateRecipe(
          recipeId: widget.recipe.id!,
          score: rating,
        );
        
        setState(() {
          _userRating = rating;
        });
        
        // Rezept neu laden um aktualisierte Durchschnittsbewertung zu bekommen
        widget.onChanged?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bewertung abgegeben: $rating ⭐'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: widget.onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe Image
                if (widget.recipe.imageUrl != null && widget.recipe.imageUrl!.isNotEmpty)
                  Image.network(
                    widget.recipe.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  )
                else
                  _buildPlaceholderImage(),
                
                // Recipe Info
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recipe.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Metadata Row
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.access_time,
                            label: '${widget.recipe.durationMinutes} Min',
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.restaurant,
                            label: '${widget.recipe.servings} Portionen',
                          ),
                          const SizedBox(width: 8),
                          _DifficultyChip(difficulty: widget.recipe.difficulty),
                        ],
                      ),
                      
                      // Tags
                      if (widget.recipe.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.recipe.tags.take(3).map((tag) {
                            return Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 12)),
                              backgroundColor: Colors.orange[100],
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ],
                      
                      // Rating Display
                      if (_totalRatings > 0) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' ($_totalRatings)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            // Ranking Badge
            if (widget.ranking != null && widget.ranking! <= 3)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRankingColor(widget.ranking!),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.ranking == 1 ? Icons.emoji_events : Icons.star,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '#${widget.ranking}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // New Badge
            if (widget.showNewBadge)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fiber_new, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'NEU',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // BUTTONS: Gespeicherte (Bookmark) & optional Bewerten (Rating)
            if (!_isLoading)
              Positioned(
                bottom: 12,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // GESPEICHERTE Button (Bookmark) - immer sichtbar
                    Material(
                      color: Colors.white,
                      elevation: 4,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _toggleFavorite,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                            color: _isFavorite ? Colors.orange : Colors.grey[600],
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    
                    // RATING Button (Stern) - nur wenn nicht versteckt
                    if (!widget.hideRatingButton) ...[
                      const SizedBox(width: 12),
                      Material(
                        color: Colors.white,
                        elevation: 4,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _showRatingDialog,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              _userRating != null ? Icons.star : Icons.star_border,
                              color: _userRating != null ? Colors.amber : Colors.grey[600],
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRankingColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Colors.orange;
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.restaurant, size: 60, color: Colors.grey),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final Difficulty difficulty;

  const _DifficultyChip({required this.difficulty});

  Color _getDifficultyColor() {
    switch (difficulty) {
      case Difficulty.einfach:
        return Colors.green;
      case Difficulty.mittel:
        return Colors.orange;
      case Difficulty.schwer:
        return Colors.red;
    }
  }

  String _getDifficultyLabel() {
    switch (difficulty) {
      case Difficulty.einfach:
        return 'Easy';
      case Difficulty.mittel:
        return 'Medium';
      case Difficulty.schwer:
        return 'Hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getDifficultyColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getDifficultyLabel(),
        style: TextStyle(
          fontSize: 12,
          color: _getDifficultyColor().withOpacity(0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ==================== RATING DIALOG ====================

class _RatingDialog extends StatefulWidget {
  final int? currentRating;

  const _RatingDialog({this.currentRating});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int? _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.currentRating;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate Recipe'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How did you like this recipe?'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final rating = index + 1;
              return IconButton(
                iconSize: 40,
                onPressed: () {
                  setState(() {
                    _selectedRating = rating;
                  });
                },
                icon: Icon(
                  rating <= (_selectedRating ?? 0) ? Icons.star : Icons.star_border,
                  color: rating <= (_selectedRating ?? 0) ? Colors.amber : Colors.grey,
                ),
              );
            }),
          ),
          if (_selectedRating != null) ...[
            const SizedBox(height: 10),
            Text(
              _getRatingText(_selectedRating!),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedRating != null
              ? () => Navigator.pop(context, _selectedRating)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: const Text('Rate'),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Bad';
      case 2:
        return 'Okay';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}