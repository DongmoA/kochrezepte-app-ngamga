import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/recipe.dart';
import '../../supabase/database_service.dart';

class ShoppingItem {
  String? id;
  String name;
  double quantity;
  String unit;
  bool isBought;

  ShoppingItem({
    this.id,
    required this.name,
    this.quantity = 0.0,
    this.unit = '',
    this.isBought = false,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      isBought: json['is_bought'] ?? false,
    );
  }

  String get formattedQuantity {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }
}

class BuyListPage extends StatefulWidget {
  const BuyListPage({super.key});

  @override
  State<BuyListPage> createState() => _BuyListPageState();
}

class _BuyListPageState extends State<BuyListPage> {
  final DatabaseService _dbService = DatabaseService();
  final List<ShoppingItem> _shoppingList = [];
  bool _isLoading = true;
  final Color _primaryColor = const Color(0xFFE65100);

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  Future<void> _loadShoppingList() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final List<Map<String, dynamic>> data = await _dbService.fetchShoppingList();
      if (mounted) {
        setState(() {
          _shoppingList.clear();
          _shoppingList.addAll(data.map((item) => ShoppingItem.fromJson(item)).toList());
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIQUE D'IMPORTATION DEPUIS LES RECETTES ---
  Future<void> _importFromRecipe() async {
    setState(() => _isLoading = true);
    try {
      final recipes = await _dbService.fetchAllRecipes(filter: RecipeFilter.all);
      if (!mounted) return;
      setState(() => _isLoading = false);

      showModalBottomSheet(
        context: context,
        builder: (context) => ListView.builder(
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return ListTile(
              leading: recipe.imageUrl != null 
                ? Image.network(recipe.imageUrl!, width: 40, height: 40, fit: BoxFit.cover)
                : const Icon(Icons.restaurant),
              title: Text(recipe.title),
              onTap: () async {
                Navigator.pop(context);
                for (var ing in recipe.ingredients) {
                  // Conversion texte -> nombre (ex: "200g" -> 200.0)
                /*String cleanQty = ing.quantity.replaceAll(RegExp(r'[^0-9.]'), '');
                 double qty = double.tryParse(cleanQty) ?? 1.0;*/
                  
                  await _dbService.addToShoppingList(ing.name,ing.quantity, ing.unit);
                }
                _loadShoppingList();
              },
            );
          },
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error importing: $e");
    }
  }

  void _addManualItem() {
    String name = '';
    double qty = 0.0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Artikel hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (val) => name = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Menge'),
              keyboardType: TextInputType.number,
              onChanged: (val) => qty = double.tryParse(val) ?? 0.0,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () async {
              if (name.isNotEmpty) {
                await _dbService.addToShoppingList(name, qty, "");
                if (mounted) Navigator.pop(context);
                _loadShoppingList();
              }
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(ShoppingItem item) {
    final nameController = TextEditingController(text: item.name);
    final qtyController = TextEditingController(text: item.formattedQuantity);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Artikel bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'Menge'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () async {
              double newQty = double.tryParse(qtyController.text) ?? 0.0;
              await _dbService.updateShoppingItemDetails(item.id!, nameController.text, newQty);
              if (mounted) Navigator.pop(context);
              _loadShoppingList();
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einkaufsliste', style: TextStyle(color: Colors.white)),
        backgroundColor: _primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              String text = "Einkaufsliste:\n" + _shoppingList.map((e) => "- ${e.formattedQuantity}${e.unit} ${e.name}").join("\n");
              Share.share(text);
            }
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView.builder(
            itemCount: _shoppingList.length,
            itemBuilder: (context, index) {
              final item = _shoppingList[index];
              return ListTile(
                leading: Checkbox(
                  value: item.isBought,
                  activeColor: _primaryColor,
                  onChanged: (val) async {
                    setState(() => item.isBought = val!);
                    await _dbService.updateShoppingItemStatus(item.id!, item.isBought);
                  },
                ),
                title: Text(item.name, style: TextStyle(decoration: item.isBought ? TextDecoration.lineThrough : null)),
                subtitle: Text("${item.formattedQuantity} ${item.unit}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditDialog(item)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                      await _dbService.deleteShoppingItem(item.id!);
                      _loadShoppingList();
                    }),
                  ],
                ),
              );
            },
          ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "importBtn",
            onPressed: _importFromRecipe,
            backgroundColor: Colors.white,
            child: Icon(Icons.restaurant, color: _primaryColor),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "addBtn",
            onPressed: _addManualItem,
            backgroundColor: _primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}