import 'package:flutter/material.dart';

class WochenplanPage extends StatefulWidget {
  const WochenplanPage({super.key});

  @override
  State<WochenplanPage> createState() => _WochenplanPageState();
}

class _WochenplanPageState extends State<WochenplanPage> {
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
  final Map<String, Map<String, String?>> _weekPlan = {};

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
  }

  void _selectRecipe(String day, String meal) {
    // TODO: Ouvrir un dialog ou une page pour sélectionner une recette
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$meal für $day'),
        content: const Text('Rezeptauswahl kommt bald...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _generateShoppingList() {
    // TODO: Générer la liste de courses basée sur les recettes sélectionnées
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Einkaufsliste wird erstellt...'),
        backgroundColor: Color(0xFFFF5722),
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
      body: Column(
        children: [
          // Bouton "Einkaufsliste erstellen"
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
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasRecipe ? selectedRecipe : 'Rezept wählen',
                      style: TextStyle(
                        fontSize: 14,
                        color: hasRecipe ? Colors.black87 : Colors.grey[500],
                      ),
                    ),
                  ),
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