import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one ingredient')),
      );
      return;
    }

    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one step')),
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
            : double.parse(_proteinController.text),
        carbs: _carbsController.text.isEmpty 
            ? null 
            : double.parse(_carbsController.text),
        fat: _fatController.text.isEmpty 
            ? null 
            : double.parse(_fatController.text),
      );

      await _dbService.createRecipe(recipe);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe saved successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (context) => _IngredientDialog(
        onAdd: (ingredient) {
          setState(() => _ingredients.add(ingredient));
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
          setState(() => _steps.add(step));
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
            setState(() => _tags.add(tag));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Recipe'),
        backgroundColor: Colors.orange,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveRecipe,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // BASIC INFO SECTION
            _buildSectionHeader('Basic Information'),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Title required' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (min) *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    decoration: const InputDecoration(
                      labelText: 'Servings *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<Difficulty>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
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
                  setState(() => _selectedDifficulty = value);
                }
              },
            ),

            const SizedBox(height: 32),

            // NUTRITION SECTION
            _buildSectionHeader('Nutrition (optional)'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _caloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Calories',
                      border: OutlineInputBorder(),
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
                      labelText: 'Protein (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      labelText: 'Carbs (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _fatController,
                    decoration: const InputDecoration(
                      labelText: 'Fat (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // INGREDIENTS SECTION
            _buildSectionHeader('Ingredients'),
            ..._ingredients.asMap().entries.map((entry) {
              return _buildListItem(
                '${entry.value.quantity} ${entry.value.unit} ${entry.value.name}',
                onDelete: () {
                  setState(() => _ingredients.removeAt(entry.key));
                },
              );
            }),
            OutlinedButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add),
              label: const Text('Add Ingredient'),
            ),

            const SizedBox(height: 32),

            // STEPS SECTION
            _buildSectionHeader('Preparation Steps'),
            ..._steps.map((step) {
              return _buildListItem(
                'Step ${step.stepNumber}: ${step.instruction}',
                onDelete: () {
                  setState(() {
                    _steps.remove(step);
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
              label: const Text('Add Step'),
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
                      setState(() => _tags.remove(tag));
                    },
                    backgroundColor: Colors.orange[100],
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addTag,
              icon: const Icon(Icons.add),
              label: const Text('Add Tag'),
            ),

            const SizedBox(height: 32),
          ],
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
        return 'Easy';
      case Difficulty.mittel:
        return 'Medium';
      case Difficulty.schwer:
        return 'Hard';
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
      title: const Text('Add Ingredient'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _unitController,
            decoration: const InputDecoration(labelText: 'Unit (e.g. g, ml, pcs)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
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
                  const SnackBar(content: Text('Please enter a valid quantity')),
                );
              }
            }
          },
          child: const Text('Add'),
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
      title: Text('Step ${widget.stepNumber}'),
      content: TextField(
        controller: _instructionController,
        decoration: const InputDecoration(labelText: 'Instruction'),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
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
          child: const Text('Add'),
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
      title: const Text('Add Tag'),
      content: TextField(
        controller: _tagController,
        decoration: const InputDecoration(labelText: 'Tag Name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_tagController.text.isNotEmpty) {
              widget.onAdd(_tagController.text.trim());
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}