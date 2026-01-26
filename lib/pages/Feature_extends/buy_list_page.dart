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
  final List<String> _units = ['g', 'kg', 'ml', 'l', 'Stück', 'TL', 'EL', 'Pkg.'];

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

/// --- MANUAL ADD LOGIC ---
  void _addManualItem() {
    String name = '';
    double qty = 0.0;
    
    // Fix for Web: Capture the list in a local variable to avoid "undefined" scope errors
    final unitsList = _units; 
    String selectedUnit = unitsList[0]; 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Artikel hinzufügen'),
          content: SingleChildScrollView( // Prevents overflow if keyboard opens
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Name (z.B. Äpfel)',
                    isDense: true,
                  ),
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Menge',
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) => qty = double.tryParse(val.replaceAll(',', '.')) ?? 0.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        isExpanded: true, // Prevents horizontal overflow
                        decoration: const InputDecoration(
                          labelText: 'Einheit',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        ),
                        // Use the local captured list here
                        items: unitsList.map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit, style: const TextStyle(fontSize: 14)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedUnit = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Abbrechen')
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              onPressed: () async {
                if (name.isNotEmpty) {
                  await _dbService.addToShoppingList(name, qty, selectedUnit);
                  if (mounted) Navigator.pop(context);
                  _loadShoppingList();
                }
              },
              child: const Text('Hinzufügen', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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

 // --- CLEAR ALL LOGIC ---
Future<void> _confirmClearList() async {
  // Show confirmation dialog 
  bool? confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Liste leeren'),
      content: const Text('Möchten Sie wirklich alle Artikel aus Ihrer Einkaufsliste löschen?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Abbrechen'), // Cancel
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Löschen', style: TextStyle(color: Colors.red)), // Delete
        ),
      ],
    ),
  );

  if (confirm == true) {
    setState(() => _isLoading = true);
    try {
      await _dbService.clearShoppingList();
      await _loadShoppingList(); // Refresh the UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Liste wurde geleert')),
        );
      }
    } catch (e) {
      debugPrint("Error clearing list: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einkaufsliste', style: TextStyle(color: Colors.white)),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed:  () async {
              final String text = "Einkaufsliste:\n${_shoppingList
              .map((e) => "- ${e.formattedQuantity}${e.unit} ${e.name}")
              .join("\n")}";

              final ShareParams params = ShareParams(
                text: text,
                 subject: 'Meine Einkaufsliste',
              );

             await SharePlus.instance.share(params);
            }
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            onPressed: _confirmClearList,
          ), 
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _shoppingList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Ihre Liste ist leer', //  Your list is empty
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fügen Sie Artikel hinzu ou importieren Sie ein Rezept', //  Add items or import recipe
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            :ListView.builder(
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