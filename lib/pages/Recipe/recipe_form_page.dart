import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kochrezepte_app/supabase/nutrition_api_service.dart';

import '../../models/recipe.dart';
import '../../supabase/database_service.dart';

class RecipeFormPage extends StatefulWidget {
  final Recipe? recipeToEdit;

  const RecipeFormPage({super.key, this.recipeToEdit});

  @override
  State<RecipeFormPage> createState() => _RecipeFormPageState();
}

class _RecipeFormPageState extends State<RecipeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();

  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _servingsController = TextEditingController();

  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  final _ingredientNameController = TextEditingController();
  final _ingredientQuantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedIngredientUnit = 'g';

  Difficulty _selectedDifficulty = Difficulty.mittel;
  MealType? _selectedMealType;

  final List<RecipeIngredient> _ingredients = [];
  final List<RecipeStep> _steps = [];
  final List<String> _tags = [];

  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImageFile;

  bool get _isEdit => widget.recipeToEdit != null;

  List<String> get _availableTags => [
    'Asiatisch',
    'Bowl',
    'Curry',
    'Fisch',
    'Gesund',
    'Italienisch',
    'Pasta',
    'Schnell',
    'Vegan',
    'Vegetarisch',
  ];

  List<String> get _availableUnits => ['g', 'ml', 'Stück', 'Teelöffel'];

  @override
  void initState() {
    super.initState();

    _titleController.addListener(_markAsChanged);
    _durationController.addListener(_markAsChanged);
    _servingsController.addListener(_markAsChanged);
    _caloriesController.addListener(_markAsChanged);
    _proteinController.addListener(_markAsChanged);
    _carbsController.addListener(_markAsChanged);
    _fatController.addListener(_markAsChanged);
    _ingredientNameController.addListener(_markAsChanged);
    _ingredientQuantityController.addListener(_markAsChanged);
    _descriptionController.addListener(_markAsChanged);

    final r = widget.recipeToEdit;
    if (r != null) {
      _titleController.text = r.title;
      _descriptionController.text = r.description ?? '';
      _durationController.text = r.durationMinutes.toString();
      _servingsController.text = r.servings.toString();
      _selectedDifficulty = r.difficulty;
      _selectedMealType = r.mealType;
      _caloriesController.text = r.calories?.toString() ?? '';
      _proteinController.text = r.protein?.toString() ?? '';
      _carbsController.text = r.carbs?.toString() ?? '';
      _fatController.text = r.fat?.toString() ?? '';

      _ingredients.addAll(r.ingredients);
      _steps.addAll(r.steps);
      _tags.addAll(r.tags);

      _hasUnsavedChanges = false;
    }
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  double? _parseDouble(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  Future<bool> _onWillPop() async {
    final hasIngredientInput =
        _ingredientNameController.text.trim().isNotEmpty ||
        _ingredientQuantityController.text.trim().isNotEmpty;

    final hasAnyInput =
        _titleController.text.trim().isNotEmpty ||
        _durationController.text.trim().isNotEmpty ||
        _servingsController.text.trim().isNotEmpty ||
        _caloriesController.text.trim().isNotEmpty ||
        _proteinController.text.trim().isNotEmpty ||
        _carbsController.text.trim().isNotEmpty ||
        _fatController.text.trim().isNotEmpty ||
        _selectedImageFile != null ||
        _ingredients.isNotEmpty ||
        _steps.isNotEmpty ||
        _tags.isNotEmpty ||
        hasIngredientInput;

    if (!_hasUnsavedChanges && !hasAnyInput) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Änderungen verwerfen?'),
        content: Text(
          hasIngredientInput && !_hasUnsavedChanges
              ? 'Du hast eine Zutat eingegeben, aber nicht hinzugefügt. Möchtest du die Seite wirklich verlassen?'
              : 'Du hast ungespeicherte Änderungen. Möchtest du die Seite wirklich verlassen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verwerfen'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _pickImageFile() async {
    try {
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bild auswählen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFFFF5722),
                ),
                title: const Text('Galerie / Dateien'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFFFF5722),
                  ),
                  title: const Text('Kamera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = image;
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden des Bildes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageFile = null;
      _hasUnsavedChanges = true;
    });
  }

  void _addIngredientDirect() {
    final name = _ingredientNameController.text.trim();
    final quantityText = _ingredientQuantityController.text.trim();

    if (name.isEmpty || quantityText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte fülle die Menge des Zutats aus'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = double.tryParse(quantityText.replaceAll(',', '.'));
    if (quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte gib eine gültige Menge ein'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _ingredients.add(
        RecipeIngredient(
          name: name,
          quantity: quantity,
          unit: _selectedIngredientUnit,
        ),
      );
      _ingredientNameController.clear();
      _ingredientQuantityController.clear();
      _selectedIngredientUnit = 'g';
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _fetchNutritionData() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Füge zuerst Zutaten hinzu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final servings = int.tryParse(_servingsController.text);
    if (servings == null || servings <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte gib die Anzahl der Portionen ein'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final nutritionService = NutritionApiService();

    final selectedNutrition = <Map<String, dynamic>>[];
    final notFoundList = <String>[];
    final skippedList = <String>[]; // NEU: Liste der übersprungenen Zutaten
    final selectedProductNames = <String, String>{};
    bool userCancelled = false;

    try {
      for (final ing in _ingredients) {
        if (userCancelled) break;

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF5722),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Suche nach "${ing.name}"...',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (selectedNutrition.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        final products = await nutritionService.searchProductsOFF(ing.name);

        if (mounted) Navigator.pop(context);

        if (products == null || products.isEmpty) {
          notFoundList.add(ing.name);

          if (mounted) {
            final shouldContinue =
                await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Keine Produkte gefunden'),
                    content: Text(
                      'Für "${ing.name}" wurden keine Produkte gefunden.\n\nMöchtest du mit den anderen Zutaten fortfahren?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Abbrechen'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Fortfahren'),
                      ),
                    ],
                  ),
                ) ??
                false;

            if (!shouldContinue) {
              userCancelled = true;
              break;
            }
          }

          continue;
        }

        dynamic selectedProduct;

        if (products.length == 1) {
          selectedProduct = products[0];
        } else {
          if (mounted) {
            selectedProduct = await showDialog<dynamic>(
              context: context,
              barrierDismissible: false,
              builder: (context) => _ProductSelectionDialog(
                ingredientName: ing.name,
                products: products,
              ),
            );
          }

          // Prüfe ob abgebrochen, übersprungen oder ausgewählt
          if (selectedProduct == null) {
            // Komplett abgebrochen
            userCancelled = true;
            break;
          } else if (selectedProduct == 'skip') {
            // Übersprungen - füge zur Skip-Liste hinzu
            skippedList.add(ing.name);
            continue;
          }
        }

        // Wenn wir hier sind, haben wir ein gültiges Produkt
        if (selectedProduct is! ProductSearchResult) {
          continue;
        }

        // Speichere das ausgewählte Produkt
        String productDisplay = selectedProduct.productName;
        if (selectedProduct.brands != null) {
          productDisplay += ' (${selectedProduct.brands})';
        }
        selectedProductNames[ing.name] = productDisplay;

        final nutritionPer100g = selectedProduct.nutritionPer100g;
        double quantityInGrams = ing.quantity;

        if (ing.unit == 'ml') {
          quantityInGrams = ing.quantity;
        } else if (ing.unit == 'Stück') {
          quantityInGrams = ing.quantity * 50;
        } else if (ing.unit == 'Teelöffel') {
          quantityInGrams = ing.quantity * 5;
        }

        final factor = quantityInGrams / 100.0;

        selectedNutrition.add({
          'name': ing.name,
          'found': true,
          'calories': nutritionPer100g['calories']! * factor,
          'protein': nutritionPer100g['protein']! * factor,
          'carbs': nutritionPer100g['carbs']! * factor,
          'fat': nutritionPer100g['fat']! * factor,
        });
      }

      if (userCancelled) {
        return;
      }

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final result in selectedNutrition) {
        totalCalories += result['calories'] as double;
        totalProtein += result['protein'] as double;
        totalCarbs += result['carbs'] as double;
        totalFat += result['fat'] as double;
      }

      final foundCount = selectedNutrition.length;

      if (foundCount == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Keine Zutaten gefunden. Bitte Nährwerte manuell eingeben.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final caloriesPerServing = totalCalories / servings;
      final proteinPerServing = totalProtein / servings;
      final carbsPerServing = totalCarbs / servings;
      final fatPerServing = totalFat / servings;

      if (mounted) {
        setState(() {
          _caloriesController.text = caloriesPerServing.round().toString();
          _proteinController.text = proteinPerServing.toStringAsFixed(1);
          _carbsController.text = carbsPerServing.toStringAsFixed(1);
          _fatController.text = fatPerServing.toStringAsFixed(1);
          _hasUnsavedChanges = true;
        });

        // Zeige Dialog mit ausgewählten Produkten
        final allFound =
            foundCount == _ingredients.length &&
            notFoundList.isEmpty &&
            skippedList.isEmpty;

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  allFound ? Icons.check_circle : Icons.warning,
                  color: allFound ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    allFound ? 'Nährwerte berechnet!' : 'Teilweise berechnet',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedProductNames.isNotEmpty) ...[
                    const Text(
                      'Verwendete Produkte:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...selectedProductNames.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (skippedList.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Übersprungen:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...skippedList.map((name) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.skip_next,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (notFoundList.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Nicht gefunden:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...notFoundList.map((name) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Pro Portion ($servings Portionen):',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildNutritionRow(
                          'Kalorien',
                          '${caloriesPerServing.round()} kcal',
                        ),
                        _buildNutritionRow(
                          'Protein',
                          '${proteinPerServing.toStringAsFixed(1)} g',
                        ),
                        _buildNutritionRow(
                          'Kohlenhydrate',
                          '${carbsPerServing.toStringAsFixed(1)} g',
                        ),
                        _buildNutritionRow(
                          'Fett',
                          '${fatPerServing.toStringAsFixed(1)} g',
                        ),
                      ],
                    ),
                  ),
                  if (skippedList.isNotEmpty || notFoundList.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nährwerte sind unvollständig. Bitte manuell ergänzen.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        for (int i = 0; i < 3 && Navigator.canPop(context); i++) {
          Navigator.pop(context);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRecipe() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte gib einen Rezeptnamen ein'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte fülle alle Pflichtfelder aus'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedImageFile == null &&
        (_isEdit == false || widget.recipeToEdit?.imageUrl == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte füge ein Bild hinzu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_durationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte gib die Zubereitungszeit ein'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_servingsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte gib die Anzahl der Portionen ein'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Füge mindestens eine Zutat hinzu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Füge mindestens einen Schritt hinzu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? finalImageUrl;

      if (_selectedImageFile != null) {
        final bytes = await _selectedImageFile!.readAsBytes();
        final fileName = _selectedImageFile!.name;

        finalImageUrl = await _dbService.uploadRecipeImage(bytes, fileName);
        if (finalImageUrl == null) {
          throw Exception('Fehler beim Hochladen des Bildes');
        }
      } else if (_isEdit && widget.recipeToEdit?.imageUrl != null) {
        finalImageUrl = widget.recipeToEdit!.imageUrl;
      }

      int? calories;
      if (_caloriesController.text.trim().isNotEmpty) {
        calories = int.tryParse(_caloriesController.text.trim());
        if (calories == null) {
          throw Exception('Ungültige Kalorienangabe');
        }
      }

      final recipe = Recipe(
        id: _isEdit ? widget.recipeToEdit!.id : '',
        ownerId: _isEdit ? widget.recipeToEdit!.ownerId : null,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        imageUrl: finalImageUrl,
        durationMinutes: int.parse(_durationController.text),
        servings: int.parse(_servingsController.text),
        difficulty: _selectedDifficulty,
        mealType: _selectedMealType,
        ingredients: List.of(_ingredients),
        steps: List.of(_steps),
        tags: List.of(_tags),
        calories: calories,
        protein: _parseDouble(_proteinController.text),
        carbs: _parseDouble(_carbsController.text),
        fat: _parseDouble(_fatController.text),
      );

      if (_isEdit) {
        await _dbService.updateRecipe(recipe);
      } else {
        await _dbService.createRecipe(recipe);
      }

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Rezept erfolgreich aktualisiert!'
                  : 'Rezept erfolgreich gespeichert!',
            ),
            backgroundColor: const Color(0xFFFF5722),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editIngredient(int index, RecipeIngredient currentIngredient) {
    showDialog(
      context: context,
      builder: (context) => _IngredientDialog(
        initialIngredient: currentIngredient,
        onAdd: (ingredient) {
          setState(() {
            _ingredients[index] = ingredient;
            _hasUnsavedChanges = true;
          });
        },
      ),
    );
  }

  void _addStep() {
    showDialog(
      context: context,
      builder: (context) => _StepDialog(
        stepNumber: _steps.length + 1,
        onAdd: (step) {
          setState(() {
            _steps.add(step);
            _hasUnsavedChanges = true;
          });
        },
      ),
    );
  }

  void _editStep(int index, RecipeStep currentStep) {
    showDialog(
      context: context,
      builder: (context) => _StepDialog(
        stepNumber: currentStep.stepNumber,
        initialInstruction: currentStep.instruction,
        onAdd: (step) {
          setState(() {
            _steps[index] = step;
            _hasUnsavedChanges = true;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            _isEdit ? 'Rezept bearbeiten' : 'Neues Rezept',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFFFF5722),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Grundinformationen Card
              _buildCard(
                title: 'Grundinformationen',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Rezeptname *'),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'z.B. Spaghetti Carbonara',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF5722),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Erforderlich'
                          : null,
                    ),

                    const SizedBox(height: 20),
                    _buildFieldLabel('Kurze Beschreibung'),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 15,
                      ),
                      decoration: _buildInputDecoration(
                        'z.B. Ein klassisches italienisches Nudelgericht mit Speck und Ei.',
                      ),
                      maxLines: 2,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 20),

                    _buildFieldLabel('Bild *'),
                    if (_selectedImageFile == null) ...[
                      InkWell(
                        onTap: _pickImageFile,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Bild auswählen',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FutureBuilder<Uint8List>(
                                future: _selectedImageFile!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    );
                                  } else if (snapshot.hasError) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(Icons.broken_image),
                                      ),
                                    );
                                  } else {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                onPressed: _removeImage,
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: ElevatedButton.icon(
                                onPressed: _pickImageFile,
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Ändern'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5722),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Zubereitungszeit (Min) *'),
                              TextFormField(
                                controller: _durationController,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 15,
                                ),
                                decoration: _buildInputDecoration('30'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Erforderlich'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Portionen *'),
                              TextFormField(
                                controller: _servingsController,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 15,
                                ),
                                decoration: _buildInputDecoration('4'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Erforderlich'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Schwierigkeit *'),
                    DropdownButtonFormField<Difficulty>(
                      value: _selectedDifficulty,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      decoration: _buildInputDecoration(''),
                      items: Difficulty.values.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(_getDifficultyLabel(d)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedDifficulty = value;
                            _hasUnsavedChanges = true;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Zutaten Card
              _buildCard(
                title: 'Zutaten *',
                child: Column(
                  children: [
                    // Zeile 1: Zutat (volle Breite)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Zutat'),
                        TextFormField(
                          controller: _ingredientNameController,
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                          ),
                          decoration: _buildInputDecoration('z.B. Mehl'),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Menge'),
                              TextFormField(
                                controller: _ingredientQuantityController,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 15,
                                ),
                                decoration: _buildInputDecoration('250'),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Einheit'),
                              DropdownButtonFormField<String>(
                                value: _selectedIngredientUnit,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                                decoration: _buildInputDecoration(''),
                                isDense: true,
                                items: _availableUnits.map((unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit,
                                    child: Text(unit),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedIngredientUnit = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addIngredientDirect,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Hinzufügen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    if (_ingredients.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      ...() {
                        final sortedIngredients =
                            List<RecipeIngredient>.from(_ingredients)..sort(
                              (a, b) => a.name.toLowerCase().compareTo(
                                b.name.toLowerCase(),
                              ),
                            );
                        return sortedIngredients.map((ing) {
                          final index = _ingredients.indexOf(ing);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    ing.name,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${ing.quantity}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ing.unit,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _editIngredient(index, ing),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _ingredients.removeAt(index);
                                      _hasUnsavedChanges = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      }(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Zubereitung Card
              _buildCard(
                title: 'Zubereitung *',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Schritt-für-Schritt Anleitung'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addStep,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Schritt hinzufügen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    if (_steps.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      ..._steps.asMap().entries.map((entry) {
                        final index = entry.key;
                        final step = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5722),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    '${step.stepNumber}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  step.instruction,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _editStep(index, step),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _steps.removeAt(index);
                                    for (int i = 0; i < _steps.length; i++) {
                                      _steps[i] = RecipeStep(
                                        stepNumber: i + 1,
                                        instruction: _steps[i].instruction,
                                      );
                                    }
                                    _hasUnsavedChanges = true;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Nährwerte Card avec API
              _buildCard(
                title: 'Nährwerte pro Portion',
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _ingredients.isEmpty
                            ? null
                            : _fetchNutritionData,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Nährwerte automatisch berechnen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'USDA FoodData Central API',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Kalorien (kcal)'),
                              TextFormField(
                                controller: _caloriesController,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 15,
                                ),
                                decoration: _buildInputDecoration('0'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Protein (g)'),
                              TextFormField(
                                controller: _proteinController,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 15,
                                ),
                                decoration: _buildInputDecoration('0'),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Kohlenhydrate (g)'),
                              TextFormField(
                                controller: _carbsController,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 15,
                                ),
                                decoration: _buildInputDecoration('0'),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Fett (g)'),
                              TextFormField(
                                controller: _fatController,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 15,
                                ),
                                decoration: _buildInputDecoration('0'),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tags Card
              _buildCard(
                title: 'Tags / Kategorien',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('🍽️ Mahlzeit'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MealType.values.map((type) {
                        final isSelected = _selectedMealType == type;
                        final label = _getMealTypeLabel(type);

                        return ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMealType = selected ? type : null;
                              _hasUnsavedChanges = true;
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: const Color(
                            0xFFFF5722,
                          ).withOpacity(0.15),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFFFF5722)
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFFFF5722)
                                  : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    _buildFieldLabel('🏷️ Tags'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _tags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _tags.add(tag);
                              } else {
                                _tags.remove(tag);
                              }
                              _hasUnsavedChanges = true;
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: const Color(
                            0xFFFF5722,
                          ).withOpacity(0.15),
                          checkmarkColor: const Color(0xFFFF5722),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFFFF5722)
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFFFF5722)
                                  : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Bottom Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      final shouldPop = await _onWillPop();
                      if (shouldPop && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      side: BorderSide(color: Colors.grey[400]!, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveRecipe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isEdit
                                ? 'Rezept aktualisieren'
                                : 'Rezept erstellen',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF5722),
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF5722), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  String _getDifficultyLabel(Difficulty d) {
    switch (d) {
      case Difficulty.einfach:
        return 'Einfach';
      case Difficulty.mittel:
        return 'Mittel';
      case Difficulty.schwer:
        return 'Schwer';
    }
  }

  String _getMealTypeLabel(MealType type) {
    switch (type) {
      case MealType.fruehstueck:
        return 'Frühstück';
      case MealType.vorspeise:
        return 'Vorspeise';
      case MealType.hauptgericht:
        return 'Hauptgericht';
      case MealType.beilage:
        return 'Beilage';
      case MealType.dessert:
        return 'Dessert';
      case MealType.snack:
        return 'Snack';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _ingredientNameController.dispose();
    _ingredientQuantityController.dispose();
    super.dispose();
  }
}

// ---------------- DIALOGS ----------------

class _IngredientDialog extends StatefulWidget {
  final Function(RecipeIngredient) onAdd;
  final RecipeIngredient? initialIngredient;

  const _IngredientDialog({required this.onAdd, this.initialIngredient});

  @override
  State<_IngredientDialog> createState() => _IngredientDialogState();
}

class _IngredientDialogState extends State<_IngredientDialog> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedUnit = 'g';

  List<String> get _availableUnits => ['g', 'ml', 'Stück', 'Teelöffel'];

  @override
  void initState() {
    super.initState();
    if (widget.initialIngredient != null) {
      _nameController.text = widget.initialIngredient!.name;
      _quantityController.text = widget.initialIngredient!.quantity.toString();
      _selectedUnit = widget.initialIngredient!.unit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialIngredient != null;

    return AlertDialog(
      title: Text(isEditing ? 'Zutat bearbeiten' : 'Zutat hinzufügen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.words,
            autofocus: !isEditing,
          ),
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(labelText: 'Menge'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedUnit,
            decoration: const InputDecoration(labelText: 'Einheit'),
            items: _availableUnits.map((unit) {
              return DropdownMenuItem<String>(value: unit, child: Text(unit));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedUnit = value;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isEmpty ||
                _quantityController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bitte fülle alle Felder des Zutats aus'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final quantity = double.tryParse(
              _quantityController.text.trim().replaceAll(',', '.'),
            );
            if (quantity == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bitte gib eine gültige Menge ein'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            widget.onAdd(
              RecipeIngredient(
                name: _nameController.text.trim(),
                quantity: quantity,
                unit: _selectedUnit,
              ),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5722),
            foregroundColor: Colors.white,
          ),
          child: Text(isEditing ? 'Aktualisieren' : 'Hinzufügen'),
        ),
      ],
    );
  }
}

class _StepDialog extends StatefulWidget {
  final int stepNumber;
  final Function(RecipeStep) onAdd;
  final String? initialInstruction;

  const _StepDialog({
    required this.stepNumber,
    required this.onAdd,
    this.initialInstruction,
  });

  @override
  State<_StepDialog> createState() => _StepDialogState();
}

class _StepDialogState extends State<_StepDialog> {
  final _instructionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialInstruction != null) {
      _instructionController.text = widget.initialInstruction!;
    }
  }

  @override
  void dispose() {
    _instructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialInstruction != null;

    return AlertDialog(
      title: Text(
        isEditing
            ? 'Schritt ${widget.stepNumber} bearbeiten'
            : 'Schritt ${widget.stepNumber}',
      ),
      content: TextField(
        controller: _instructionController,
        decoration: const InputDecoration(labelText: 'Anweisung'),
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        autofocus: !isEditing,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_instructionController.text.isNotEmpty) {
              widget.onAdd(
                RecipeStep(
                  stepNumber: widget.stepNumber,
                  instruction: _instructionController.text.trim(),
                ),
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5722),
            foregroundColor: Colors.white,
          ),
          child: Text(isEditing ? 'Aktualisieren' : 'Hinzufügen'),
        ),
      ],
    );
  }
}

// Produkt-Auswahl-Dialog
class _ProductSelectionDialog extends StatelessWidget {
  final String ingredientName;
  final List<ProductSearchResult> products;

  const _ProductSelectionDialog({
    required this.ingredientName,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Produkt auswählen',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'für "$ingredientName"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final nutrition = product.nutritionPer100g;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: InkWell(
                onTap: () => Navigator.pop(context, product),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (product.brands != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.brands!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Pro 100g: ${nutrition['calories']!.round()}kcal | '
                        'P: ${nutrition['protein']!.toStringAsFixed(1)}g | '
                        'C: ${nutrition['carbs']!.toStringAsFixed(1)}g | '
                        'F: ${nutrition['fat']!.toStringAsFixed(1)}g',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: product.completeness / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                product.completeness > 70
                                    ? Colors.green
                                    : product.completeness > 40
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${product.completeness.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'skip'),
          style: TextButton.styleFrom(foregroundColor: Colors.orange),
          child: const Text('Überspringen'),
        ),
      ],
    );
  }
}
