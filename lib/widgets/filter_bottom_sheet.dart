import 'package:flutter/material.dart';
import '../models/recipe.dart';
class FilterBottomSheet extends StatefulWidget {
  final List<String> selectedTags;
  final String? selectedTime;
  final MealType? selectedMealType;
  final Function(List<String> tags, String? selectedTime, MealType? selectedMealType) onApply;

  const FilterBottomSheet({
    super.key,
    required this.selectedTags,
    required this.selectedTime,
    this.selectedMealType,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late List<String> _selectedTags;
  late String? _selectedTime;
  late MealType? _selectedMealType;

  final List<String> _availableTags = [
    'Italienisch',
    'Pasta',
    'Schnell',
    'Vegan',
    'Gesund',
    'Bowl',
    'Fisch',
    'Vegetarisch',
    'Curry',
    'Asiatisch',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.selectedTags);
    _selectedTime = widget.selectedTime;
    _selectedMealType = widget.selectedMealType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTags.clear();
                      _selectedTime = null;
                      _selectedMealType = null;
                    });
                  },
                  child: Text(
                    'Zurücksetzen',
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                ),
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onApply(_selectedTags, _selectedTime, _selectedMealType);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Anwenden',
                    style: TextStyle(
                      color: Color(0xFFE65100),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
  'Mahlzeit',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
const SizedBox(height: 16),
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
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFE65100).withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFE65100) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFFE65100) : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }).toList(),
),
const SizedBox(height: 32),

                  const Text(
                    'Zubereitungszeit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['0-20', '20-30', '30-45', '45-60', '60-90', '90+'].map((
                      time,
                    ) {
                      final isSelected = _selectedTime == time;
                      return ChoiceChip(
                        label: Text('$time Min'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTime = selected ? time : null;
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFFE65100).withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFFE65100)
                              : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFE65100)
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
                  const SizedBox(height: 32),
                  const Text(
                    'Tags',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFFE65100).withOpacity(0.1),
                        checkmarkColor: const Color(0xFFE65100),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFFE65100)
                              : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFE65100)
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
          ),
        ],
      ),
    );
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
}
