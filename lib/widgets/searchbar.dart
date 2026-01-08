import 'package:flutter/material.dart';

class RecipeSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearch;

  const RecipeSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Rezepte suchen...',
        hintStyle: const TextStyle(color: Colors.white70, fontSize: 15),
        prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
    );
  }
}
