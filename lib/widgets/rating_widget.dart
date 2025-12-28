import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../../supabase/database_service.dart'; 

/// A dedicated widget for displaying and managing recipe ratings.
class RecipeRatingWidget extends StatefulWidget {
  final Recipe recipe;

  const RecipeRatingWidget({super.key, required this.recipe});

  @override
  State<RecipeRatingWidget> createState() => _RecipeRatingWidgetState();
}

class _RecipeRatingWidgetState extends State<RecipeRatingWidget> {
  final DatabaseService _dbService = DatabaseService();
  
  // State variables for the widget
  double _averageRating = 0.0;
  int _totalRatings = 0;
  
  // User's current rating (can be null if not rated, or 1-5 if rated/in-progress)
  int? _userRating; 
  // Staging variable for the user's interaction (the score they are about to submit)
  int? _pendingScore; 
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _averageRating = widget.recipe.averageRating;
    _totalRatings = widget.recipe.totalRatings;
    _loadUserRating();
  }

  /// Loads the rating given by the current user for this recipe.
  Future<void> _loadUserRating() async {
    setState(() => _isLoading = true);
    try {
      final score = await _dbService.fetchUserRating(widget.recipe.id!);
      if (mounted) {
        setState(() {
          _userRating = score;
          _pendingScore = score;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Error handling could be more sophisticated, but a simple print is enough for now.
        debugPrint('Error loading user rating: $e');
      }
    }
  }
  
  /// Submits the pending score to the database.
  Future<void> _submitRating() async {
    if (_pendingScore == null || _pendingScore! < 1 || _pendingScore! > 5) return;

    setState(() => _isLoading = true);

    try {
      // 1. Submit rating to Supabase
      await _dbService.rateRecipe(
        recipeId: widget.recipe.id!,
        score: _pendingScore!,
      );

      // 2. Fetch the new aggregated data from the recipe table (or assume success and update cache)
      // Since the rateRecipe function updates the cache on the server, we need to read it back.
      // For simplicity here, we'll assume the Recipe model has fields for averageRating/totalRatings
      // and update them directly after a slight delay (in a real app, this should be a fresh fetch).
      // Since we don't have a specific endpoint to fetch *only* the new aggregate stats easily,
      // we'll rely on the fact that rateRecipe updates the cache and show a success message.
      
      // A full re-fetch of the recipe would be safer in a production app.
      
      // For now, we update the local state to reflect the user's new rating.
      if (mounted) {
        setState(() {
          _userRating = _pendingScore;
          _isLoading = false;
          // Note: The average and total ratings might be slightly out of sync 
          // until the parent page reloads, but the user's rating is correct.
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bewertung erfolgreich gesendet!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Senden der Bewertung: $e')),
        );
      }
    }
  }

  /// Builds a single star icon based on the index and the pending score.
  Widget _buildStar(int index) {
    // The star is filled if its index (1-5) is less than or equal to the pending score.
    final bool isSelected = index <= (_pendingScore ?? 0);
    
    // Choose color: gold for selected, grey for unselected.
    final color = isSelected ? Colors.amber : Colors.grey[300];

    return InkWell(
      onTap: _isLoading ? null : () {
        setState(() {
          // Set the pending score to the index of the tapped star.
          _pendingScore = index;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Icon(
          Icons.star_rounded,
          size: 32.0,
          color: color,
        ),
      ),
    );
  }

  /// Builds the text message/prompt displayed below the stars.
  Widget _buildPromptMessage() {
    if (_userRating != null) {
      // User has already rated
      return Text(
        'You have rated this recipe $_userRating stars. '
        'Average: ${_averageRating.toStringAsFixed(1)} ($_totalRatings votes)',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: Colors.green),
      );
    } 
    
    if (_pendingScore != null && _pendingScore! > 0) {
      // User has selected a score but not submitted
      return ElevatedButton(
        onPressed: _submitRating,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        child: const Text('Submit Rating', style: TextStyle(color: Colors.white)),
      );
    }
    
    // Default message: user is prompted to rate
    return const Text(
      'Rate this recipe!',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 14, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If the widget is loading data from the database, show a placeholder.
    if (_isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ));
    }
    
    // The main layout of the rating system
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          // 1. Stars Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => _buildStar(index + 1)),
          ),
          const SizedBox(height: 12),
          
          // 2. Prompt/Submission Message
          _buildPromptMessage(),
          
          // 3. Display current average if user hasn't rated yet
          if (_userRating == null && _totalRatings > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Average: ${_averageRating.toStringAsFixed(1)} (${_totalRatings} votes)',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}