import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../../supabase/database_service.dart';

class RecipeRatingWidget extends StatefulWidget {
  final Recipe recipe;
  final Function(double,int) onRaitingSucess;

  const RecipeRatingWidget({super.key, required this.recipe, required this.onRaitingSucess});

  @override
  State<RecipeRatingWidget> createState() => _RecipeRatingWidgetState();
}

class _RecipeRatingWidgetState extends State<RecipeRatingWidget> {
  final DatabaseService _dbService = DatabaseService();
  static const Color figmaOrange = Color(0xFFFF5722);
  
  // State variables
  double _averageRating = 0.0;
  int _totalRatings = 0;
  int? _userRating; 
  int? _pendingScore; 
  bool _isLoading = true;
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _allReviews = [];

  @override
  void initState() {
    super.initState();
    // initialize with recipe data
    _averageRating = widget.recipe.averageRating;
    _totalRatings = widget.recipe.totalRatings;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Load both user rating and all reviews in parallel
      await Future.wait([
        _checkIfUserRated(),
        _refreshReviews(),
      ]);
    } catch (e) {
      debugPrint("Erreur chargement initial: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // verify if the current user has already rated this recipe
  Future<void> _checkIfUserRated() async {
    final rating = await _dbService.fetchUserRating(widget.recipe.id!);
    if (mounted) setState(() => _userRating = rating);
  }

  Future<void> _refreshReviews() async {
    final reviews = await _dbService.fetchAllRatingsForRecipe(widget.recipe.id!);
    if (mounted) setState(() => _allReviews = reviews);
  }

  Future<void> _submitRating() async {
    if (_pendingScore == null) return;
    setState(() => _isLoading = true);

    try {
      // 1. Submit the rating
      final result = await _dbService.rateRecipe(
        recipeId: widget.recipe.id!,
        score: _pendingScore!,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );

      // 2. Refresh reviews
      await _refreshReviews();

      if (mounted) {
        setState(() {
          _userRating = _pendingScore; //  mark as rated
          _averageRating = result['average']; // update average
          _totalRatings = result['total'];    // update total
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler: ${e.toString()}")),
        );
      }
    }
    // notifiy parent about new rating
    widget.onRaitingSucess(_averageRating, _totalRatings);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: figmaOrange));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
 
        const SizedBox(height: 24),
        
        // section to rate the recipe or see existing reviews
        if (_userRating == null) 
          _buildVotingForm() 
        else
        // List of  existing reviews
        _buildReviewList(),
      ],
    );
  }



  Widget _buildVotingForm() {
    return Column(
      children: [
        const Text('Bewerten Sie dieses Rezept', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) => _buildStarButton(index + 1)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: 'Schreibe einen Kommentar...',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            onPressed: _pendingScore != null ? _submitRating : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: figmaOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Bewertung abgeben', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }


  Widget _buildReviewList() {
    if (_allReviews.isEmpty) return const Center(child: Text("Noch keine Kommentare."));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allReviews.length,
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(thickness: 0.5),
      ),
      itemBuilder: (context, index) {
        final review = _allReviews[index];
        
        // Format date as DD.MM.YYYY
        String rawDate = review['created_at'].toString().split('T')[0];
        List<String> parts = rawDate.split('-');
        String formattedDate = parts.length == 3 ? "${parts[2]}.${parts[1]}.${parts[0]}" : rawDate;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // left: User name and comment
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review['user_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  if (review['comment'] != null)
                    Text(review['comment'], style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(formattedDate, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            // right: Star rating
            Row(
              children: List.generate(5, (i) => Icon(
                i < (review['score'] as int) ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 14, // smaller size for review stars
              )),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStarButton(int index) {
    final bool isSelected = index <= (_pendingScore ?? 0);
    return IconButton(
      onPressed: () => setState(() => _pendingScore = index),
      icon: Icon(
        isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
        size: 38,
        color: isSelected ? Colors.amber : Colors.grey[300],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}