import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; 
import '../../models/recipe.dart';
import '../../supabase/database_service.dart';

class ShoppingItem {
  String name;
  String quantity;
  String unit;
  bool isBought;

  ShoppingItem({
    required this.name,
    this.quantity = '',
    this.unit = '',
    this.isBought = false,
  });
}

class BuyListPage extends StatefulWidget {
  const BuyListPage({super.key});

  @override
  State<BuyListPage> createState() => _BuyListPageState();
}

class _BuyListPageState extends State<BuyListPage> {
  final DatabaseService _dbService = DatabaseService();
  final List<ShoppingItem> _shoppingList = [];
  final Color _primaryColor = const Color(0xFFE65100);

  // Add a manual item to the shopping list
  void _addManualItem() {
    String name = '';
    String qty = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Artikel hinzufügen'), //  Add item
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name (z.B. Milch)'), //  Name (e.g. Milk)
              onChanged: (val) => name = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Menge (z.B. 1L)'), // Quantity
              onChanged: (val) => qty = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Abbrechen') //  Cancel
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            onPressed: () {
              if (name.isNotEmpty) {
                setState(() => _shoppingList.add(ShoppingItem(name: name, quantity: qty)));
                Navigator.pop(context);
              }
            },
            child: const Text('Hinzufügen', style: TextStyle(color: Colors.white)), //  Add
          ),
        ],
      ),
    );
  }

  // Select a recipe to import its ingredients
  void _importFromRecipe() async {
    final recipes = await _dbService.fetchAllRecipes(filter: RecipeFilter.all);
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aus Rezept importieren', //  Import from recipe
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return ListTile(
                    leading: const Icon(Icons.restaurant, color: Color(0xFFE65100)),
                    title: Text(recipe.title),
                    onTap: () {
                      setState(() {
                        for (var ing in recipe.ingredients) {
                          _shoppingList.add(ShoppingItem(
                            name: ing.name,
                            quantity: ing.quantity.toString(),
                            unit: ing.unit,
                          ));
                        }
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Zutaten hinzugefügt!')) //  Ingredients added
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Share the list via external apps
  void _shareList() {
    if (_shoppingList.isEmpty) return;
    String listText = "🛒 Meine Einkaufsliste:\n"; // German: My shopping list
    for (var item in _shoppingList) {
      String status = item.isBought ? "[X]" : "[ ]";
      listText += "$status ${item.name} (${item.quantity} ${item.unit})\n";
    }
    Share.share(listText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einkaufsliste', style: TextStyle(fontWeight: FontWeight.bold)), //  Shopping List
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareList,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => setState(() => _shoppingList.clear()),
          ),
        ],
      ),
      body: _shoppingList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Ihre Liste ist leer', style: TextStyle(color: Colors.grey[600], fontSize: 18)), // German: Your list is empty
                ],
              ),
            )
          : ListView.builder(
              itemCount: _shoppingList.length,
              itemBuilder: (context, index) {
                final item = _shoppingList[index];
                return Dismissible(
                  key: UniqueKey(),
                  background: Container(
                    color: Colors.red, 
                    alignment: Alignment.centerRight, 
                    padding: const EdgeInsets.only(right: 20), 
                    child: const Icon(Icons.delete, color: Colors.white)
                  ),
                  onDismissed: (direction) => setState(() => _shoppingList.removeAt(index)),
                  child: CheckboxListTile(
                    activeColor: _primaryColor,
                    title: Text(item.name, 
                      style: TextStyle(
                        decoration: item.isBought ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.w500
                      )),
                    subtitle: Text("${item.quantity} ${item.unit}"),
                    value: item.isBought,
                    onChanged: (bool? value) {
                      setState(() => item.isBought = value ?? false);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "btn1",
            onPressed: _importFromRecipe,
            backgroundColor: Colors.white,
            tooltip: 'Aus Rezept importieren', //  Import from recipe
            child: Icon(Icons.restaurant, color: _primaryColor),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "btn2",
            onPressed: _addManualItem,
            backgroundColor: _primaryColor,
            tooltip: 'Artikel hinzufügen', //  Add item
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}