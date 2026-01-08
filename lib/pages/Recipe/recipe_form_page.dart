// lib/pages/recipe/recipe_form_page.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

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
  final _imageUrlController = TextEditingController();
  final _durationController = TextEditingController();
  final _servingsController = TextEditingController();

  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  Difficulty _selectedDifficulty = Difficulty.mittel;

  final List<RecipeIngredient> _ingredients = [];
  final List<RecipeStep> _steps = [];
  final List<String> _tags = [];

  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImageFile;

  bool get _isEdit => widget.recipeToEdit != null;

  @override
  void initState() {
    super.initState();

    // Track changes for exit confirmation
    _titleController.addListener(_markAsChanged);
    _imageUrlController.addListener(_markAsChanged);
    _durationController.addListener(_markAsChanged);
    _servingsController.addListener(_markAsChanged);
    _caloriesController.addListener(_markAsChanged);
    _proteinController.addListener(_markAsChanged);
    _carbsController.addListener(_markAsChanged);
    _fatController.addListener(_markAsChanged);

    // Prefill on edit
    final r = widget.recipeToEdit;
    if (r != null) {
      _titleController.text = r.title;
      _imageUrlController.text = r.imageUrl ?? '';
      _durationController.text = r.durationMinutes.toString();
      _servingsController.text = r.servings.toString();
      _selectedDifficulty = r.difficulty;

      _caloriesController.text = r.calories?.toString() ?? '';
      _proteinController.text = r.protein?.toString() ?? '';
      _carbsController.text = r.carbs?.toString() ?? '';
      _fatController.text = r.fat?.toString() ?? '';

      _ingredients.addAll(r.ingredients);
      _steps.addAll(r.steps);
      _tags.addAll(r.tags);

      // On edit, we start "clean" (no unsaved changes yet)
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
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Änderungen verwerfen?'),
        content: const Text(
          'Du hast ungespeicherte Änderungen. Möchtest du die Seite wirklich verlassen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
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
                leading: const Icon(Icons.photo_library, color: Colors.orange),
                title: const Text('Galerie / Dateien'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.orange),
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
          _imageUrlController.clear();
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
      _imageUrlController.clear();
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte fülle alle Pflichtfelder aus')),
      );
      return;
    }

    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Füge mindestens einen Schritt hinzu')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? finalImageUrl;

      // 1) If local file selected -> upload
      if (_selectedImageFile != null) {
        final bytes = await _selectedImageFile!.readAsBytes();
        final fileName = _selectedImageFile!.name;

        finalImageUrl = await _dbService.uploadRecipeImage(bytes, fileName);
        if (finalImageUrl == null) {
          throw Exception('Fehler beim Hochladen des Bildes');
        }
      }
      // 2) else if URL typed -> use it
      else if (_imageUrlController.text.trim().isNotEmpty) {
        finalImageUrl = _imageUrlController.text.trim();
      }
      // 3) else null

      final recipe = Recipe(
        id: _isEdit ? widget.recipeToEdit!.id : '',
        ownerId: _isEdit ? widget.recipeToEdit!.ownerId : null,
        title: _titleController.text.trim(),
        imageUrl: finalImageUrl,
        durationMinutes: int.parse(_durationController.text),
        servings: int.parse(_servingsController.text),
        difficulty: _selectedDifficulty,
        ingredients: List.of(_ingredients),
        steps: List.of(_steps),
        tags: List.of(_tags),
        calories: _caloriesController.text.trim().isEmpty
            ? null
            : int.parse(_caloriesController.text),
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
            content: Text(_isEdit
                ? 'Rezept erfolgreich aktualisiert!'
                : 'Rezept erfolgreich gespeichert!'),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    }
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (context) => _IngredientDialog(
        onAdd: (ingredient) {
          setState(() {
            _ingredients.add(ingredient);
            _hasUnsavedChanges = true;
          });
        },
      ),
    );
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

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) => _TagDialog(
        onAdd: (tag) {
          if (!_tags.contains(tag)) {
            setState(() {
              _tags.add(tag);
              _hasUnsavedChanges = true;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Rezept bearbeiten' : 'Neues Rezept',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.orange,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Grundinformationen'),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Titel erforderlich' : null,
              ),

              const SizedBox(height: 16),

              // Image section: URL OR local file
              if (_selectedImageFile == null &&
                  _imageUrlController.text.trim().isEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Bild-URL (optional)',
                          border: OutlineInputBorder(),
                          hintText: 'https://example.com/image.jpg',
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            setState(() => _selectedImageFile = null);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        IconButton(
                          onPressed: _pickImageFile,
                          icon: const Icon(Icons.add_photo_alternate),
                          tooltip: 'Bild auswählen',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Bild', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _selectedImageFile != null
                                ? FutureBuilder<Uint8List>(
                                    future: _selectedImageFile!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          height: 200,
                                          fit: BoxFit.contain,
                                        );
                                      } else if (snapshot.hasError) {
                                        return SizedBox(
                                          width: MediaQuery.of(context).size.width,
                                          child: Container(
                                            color: Colors.grey[300],
                                            child: const Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.broken_image,
                                                    size: 50, color: Colors.grey),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Bild konnte nicht geladen werden',
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      } else {
                                        return SizedBox(
                                          width: MediaQuery.of(context).size.width,
                                          child: Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  )
                                : Image.network(
                                    _imageUrlController.text.trim(),
                                    height: 200,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return SizedBox(
                                        width: MediaQuery.of(context).size.width,
                                        child: Container(
                                          color: Colors.grey[300],
                                          child: const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image,
                                                  size: 50, color: Colors.grey),
                                              SizedBox(height: 8),
                                              Text(
                                                'Bild konnte nicht geladen werden',
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return SizedBox(
                                        width: MediaQuery.of(context).size.width,
                                        child: Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: _removeImage,
                              icon: const Icon(Icons.close),
                              tooltip: 'Bild entfernen',
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
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Dauer (Min) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Erforderlich' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _servingsController,
                      decoration: const InputDecoration(
                        labelText: 'Portionen *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Erforderlich' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<Difficulty>(
                value: _selectedDifficulty,
                decoration: const InputDecoration(
                  labelText: 'Schwierigkeit',
                  border: OutlineInputBorder(),
                ),
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

              const SizedBox(height: 32),

              _buildSectionHeader('Nährwerte (optional)'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(
                        labelText: 'Kalorien',
                        border: OutlineInputBorder(),
                        suffix: Text('kcal'),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Protein',
                        border: OutlineInputBorder(),
                        suffix: Text('g'),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Kohlenhydrate',
                        border: OutlineInputBorder(),
                        suffix: Text('g'),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      decoration: const InputDecoration(
                        labelText: 'Fett',
                        border: OutlineInputBorder(),
                        suffix: Text('g'),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              _buildSectionHeader('Zutaten (optional)'),
              if (_ingredients.isNotEmpty)
                ..._ingredients.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ingredient = entry.value;
                  return _buildListItem(
                    '${ingredient.quantity} ${ingredient.unit} ${ingredient.name}',
                    onEdit: () => _editIngredient(index, ingredient),
                    onDelete: () {
                      setState(() {
                        _ingredients.removeAt(index);
                        _hasUnsavedChanges = true;
                      });
                    },
                  );
                }),
              OutlinedButton.icon(
                onPressed: _addIngredient,
                icon: const Icon(Icons.add),
                label: const Text('Zutat hinzufügen'),
              ),

              const SizedBox(height: 32),

              _buildSectionHeader('Zubereitung'),
              if (_steps.isNotEmpty)
                ..._steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  return _buildListItem(
                    'Schritt ${step.stepNumber}: ${step.instruction}',
                    onEdit: () => _editStep(index, step),
                    onDelete: () {
                      setState(() {
                        _steps.removeAt(index);
                        _hasUnsavedChanges = true;
                        for (int i = 0; i < _steps.length; i++) {
                          _steps[i] = RecipeStep(
                            stepNumber: i + 1,
                            instruction: _steps[i].instruction,
                          );
                        }
                      });
                    },
                  );
                }),
              OutlinedButton.icon(
                onPressed: _addStep,
                icon: const Icon(Icons.add),
                label: const Text('Schritt hinzufügen'),
              ),

              const SizedBox(height: 32),

              _buildSectionHeader('Tags'),
              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () {
                        setState(() {
                          _tags.remove(tag);
                          _hasUnsavedChanges = true;
                        });
                      },
                      backgroundColor: Colors.orange[100],
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addTag,
                icon: const Icon(Icons.add),
                label: const Text('Tag hinzufügen'),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveRecipe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? 'Wird gespeichert...' : 'Rezept speichern',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  Widget _buildListItem(
    String text, {
    required VoidCallback onDelete,
    VoidCallback? onEdit,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(text),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
                tooltip: 'Bearbeiten',
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Löschen',
            ),
          ],
        ),
      ),
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

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _durationController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }
}

// ---------------- DIALOGS ----------------

class _IngredientDialog extends StatefulWidget {
  final Function(RecipeIngredient) onAdd;
  final RecipeIngredient? initialIngredient;

  const _IngredientDialog({
    required this.onAdd,
    this.initialIngredient,
  });

  @override
  State<_IngredientDialog> createState() => _IngredientDialogState();
}

class _IngredientDialogState extends State<_IngredientDialog> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialIngredient != null) {
      _nameController.text = widget.initialIngredient!.name;
      _quantityController.text =
          widget.initialIngredient!.quantity.toString();
      _unitController.text = widget.initialIngredient!.unit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
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
          TextField(
            controller: _unitController,
            decoration:
                const InputDecoration(labelText: 'Einheit (z.B. g, ml, Stück)'),
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
            if (_nameController.text.isNotEmpty &&
                _quantityController.text.isNotEmpty &&
                _unitController.text.isNotEmpty) {
              final quantity = double.tryParse(
                _quantityController.text.trim().replaceAll(',', '.'),
              );
              if (quantity != null) {
                widget.onAdd(RecipeIngredient(
                  name: _nameController.text.trim(),
                  quantity: quantity,
                  unit: _unitController.text.trim(),
                ));
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bitte gib eine gültige Menge ein')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
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
      title: Text(isEditing
          ? 'Schritt ${widget.stepNumber} bearbeiten'
          : 'Schritt ${widget.stepNumber}'),
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
              widget.onAdd(RecipeStep(
                stepNumber: widget.stepNumber,
                instruction: _instructionController.text.trim(),
              ));
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: Text(isEditing ? 'Aktualisieren' : 'Hinzufügen'),
        ),
      ],
    );
  }
}

class _TagDialog extends StatefulWidget {
  final Function(String) onAdd;

  const _TagDialog({required this.onAdd});

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tag hinzufügen'),
      content: TextField(
        controller: _tagController,
        decoration: const InputDecoration(labelText: 'Tag-Name'),
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_tagController.text.isNotEmpty) {
              widget.onAdd(_tagController.text.trim());
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}
