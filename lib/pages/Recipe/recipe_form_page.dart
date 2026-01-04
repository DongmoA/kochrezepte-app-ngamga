import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../models/recipe.dart';
import '../../supabase/database_service.dart';

class RecipeFormPage extends StatefulWidget {
  const RecipeFormPage({super.key});

  @override
  State<RecipeFormPage> createState() => _RecipeFormPageState();
}

class _RecipeFormPageState extends State<RecipeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();
  
  // Basic Info Controllers
  final _titleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _durationController = TextEditingController();
  final _servingsController = TextEditingController();
  
  // Nutrition Controllers
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  
  Difficulty _selectedDifficulty = Difficulty.mittel;
  
  // Dynamic Lists
  final List<RecipeIngredient> _ingredients = [];
  final List<RecipeStep> _steps = [];
  final List<String> _tags = [];
  
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  
  File? _selectedImageFile;

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
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<void> _pickImageFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImageFile = File(result.files.single.path!);
          _imageUrlController.clear(); // Clear URL if local image is selected
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden des Bildes: $e')),
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

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte fülle alle Pflichtfelder aus')),
      );
      return;
    }

    // Ingredients are now optional, so we removed this check

    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Füge mindestens einen Schritt hinzu')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final recipe = Recipe(
        id: '', 
        title: _titleController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty 
            ? null 
            : _imageUrlController.text.trim(),
        durationMinutes: int.parse(_durationController.text),
        servings: int.parse(_servingsController.text),
        difficulty: _selectedDifficulty,
        ingredients: _ingredients,
        steps: _steps,
        tags: _tags,
        calories: _caloriesController.text.isEmpty 
            ? null 
            : int.parse(_caloriesController.text),
        protein: _proteinController.text.isEmpty 
            ? null 
            : double.parse(_proteinController.text.replaceAll(',', '.')),
        carbs: _carbsController.text.isEmpty 
            ? null 
            : double.parse(_carbsController.text.replaceAll(',', '.')),
        fat: _fatController.text.isEmpty 
            ? null 
            : double.parse(_fatController.text.replaceAll(',', '.')),
      );

      await _dbService.createRecipe(recipe);

      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rezept erfolgreich gespeichert!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
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
          title: const Text('Neues Rezept', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.orange,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // BASIC INFO SECTION
              _buildSectionHeader('Grundinformationen'),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Titel erforderlich' : null,
              ),
              const SizedBox(height: 16),
              
              // Image Selection Section
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
                          setState(() => _selectedImageFile = null); // Clear local file if URL is entered
                        }
                      },
                      enabled: _selectedImageFile == null, // Disable if local image is selected
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton(
                        onPressed: _pickImageFile,
                        icon: const Icon(Icons.folder_open),
                        tooltip: 'Bild auswählen',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Datei', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              
              // Image Preview
              if (_selectedImageFile != null || _imageUrlController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _selectedImageFile != null
                          ? Image.file(
                              _selectedImageFile!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              _imageUrlController.text.trim(),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'Bild konnte nicht geladen werden',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
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
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
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
                      validator: (v) => v?.isEmpty ?? true ? 'Erforderlich' : null,
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
                      validator: (v) => v?.isEmpty ?? true ? 'Erforderlich' : null,
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

              // NUTRITION SECTION
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, // Only digits allowed
                      ],
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Numbers with max 2 decimals
                      ],
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Numbers with max 2 decimals
                      ],
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Numbers with max 2 decimals
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // INGREDIENTS SECTION (now optional)
              _buildSectionHeader('Zutaten (optional)'),
              if (_ingredients.isNotEmpty)
                ..._ingredients.map((ingredient) {
                  return _buildListItem(
                    '${ingredient.quantity} ${ingredient.unit} ${ingredient.name}',
                    onDelete: () {
                      setState(() {
                        _ingredients.remove(ingredient);
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

              // STEPS SECTION
              _buildSectionHeader('Zubereitung'),
              if (_steps.isNotEmpty)
                ..._steps.map((step) {
                  return _buildListItem(
                    'Schritt ${step.stepNumber}: ${step.instruction}',
                    onDelete: () {
                      setState(() {
                        _steps.remove(step);
                        _hasUnsavedChanges = true;
                        // Renumber steps
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

              // TAGS SECTION
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

              // SAVE BUTTON (improved)
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildListItem(String text, {required VoidCallback onDelete}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(text),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
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
}

// DIALOGS

class _IngredientDialog extends StatefulWidget {
  final Function(RecipeIngredient) onAdd;

  const _IngredientDialog({required this.onAdd});

  @override
  State<_IngredientDialog> createState() => _IngredientDialogState();
}

class _IngredientDialogState extends State<_IngredientDialog> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Zutat hinzufügen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.words,
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
            decoration: const InputDecoration(labelText: 'Einheit (z.B. g, ml, Stück)'),
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
              final quantity = double.tryParse(_quantityController.text.trim().replaceAll(',', '.'));
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
          child: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}

class _StepDialog extends StatefulWidget {
  final int stepNumber;
  final Function(RecipeStep) onAdd;

  const _StepDialog({required this.stepNumber, required this.onAdd});

  @override
  State<_StepDialog> createState() => _StepDialogState();
}

class _StepDialogState extends State<_StepDialog> {
  final _instructionController = TextEditingController();

  @override
  void dispose() {
    _instructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Schritt ${widget.stepNumber}'),
      content: TextField(
        controller: _instructionController,
        decoration: const InputDecoration(labelText: 'Anweisung'),
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
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
          child: const Text('Hinzufügen'),
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