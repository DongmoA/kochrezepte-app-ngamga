import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ProductSearchResult {
  final String productName;
  final String? brands;
  final Map<String, double> nutritionPer100g;
  final double completeness;

  ProductSearchResult({
    required this.productName,
    this.brands,
    required this.nutritionPer100g,
    required this.completeness,
  });
}

class NutritionApiService {
  static const String _offBaseUrl = 'https://world.openfoodfacts.org/cgi/search.pl';
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxRetries = 3;

  Future<List<ProductSearchResult>?> searchProductsOFF(String ingredientName, {int attempt = 1}) async {
    try {
      final queryParams = {
        'search_terms': ingredientName,
        'action': 'process',
        'json': '1',
        'page_size': '20',
        'fields': 'product_name,nutriments,brands,completeness',
        'sort_by': 'unique_scans_n',
      };

      final uri = Uri.parse(_offBaseUrl).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'KochrezepteApp/1.0',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          
          final productCount = data['count'] ?? 0;
          
          if (productCount == 0) {
            if (attempt < _maxRetries) {
              await Future.delayed(const Duration(seconds: 2));
              return searchProductsOFF(ingredientName, attempt: attempt + 1);
            }
            return null;
          }
          
          if (data['products'] != null && (data['products'] as List).isNotEmpty) {
            final productsList = data['products'] as List;
            
            final List<ProductSearchResult> results = [];
            
            for (int i = 0; i < productsList.length; i++) {
              final product = productsList[i];
              try {
                final productName = (product['product_name'] ?? '').toString();
                
                if (productName.isEmpty) continue;
                
                final productNameLower = productName.toLowerCase();
                final searchLower = ingredientName.toLowerCase();
                
                final containsSearch = productNameLower.contains(searchLower);
                final searchContainsProduct = searchLower.contains(productNameLower);
                final similar = _areSimilar(productNameLower, searchLower);
                
                final isRelevant = containsSearch || searchContainsProduct || similar;
                
                if (!isRelevant) {
                  continue;
                }
                
                final nutriments = product['nutriments'];
                
                if (nutriments == null || nutriments is! Map) {
                  continue;
                }
                
                final nutrimentsMap = Map<String, dynamic>.from(nutriments as Map);
              
                final calories = _getDoubleValue(nutrimentsMap, [
                  'energy-kcal_100g',
                  'energy_100g',
                  'energy-kcal',
                ]);
                
                final protein = _getDoubleValue(nutrimentsMap, [
                  'proteins_100g',
                  'proteins',
                ]);
                
                final carbs = _getDoubleValue(nutrimentsMap, [
                  'carbohydrates_100g',
                  'carbohydrates',
                ]);
                
                final fat = _getDoubleValue(nutrimentsMap, [
                  'fat_100g',
                  'fat',
                ]);

                double finalCalories = calories;
                if (finalCalories == 0 && nutrimentsMap['energy-kj_100g'] != null) {
                  try {
                    finalCalories = (nutrimentsMap['energy-kj_100g'] as num).toDouble() / 4.184;
                  } catch (e) {
                    // Ignoriere Fehler
                  }
                }

                if (finalCalories > 0 || protein > 0 || carbs > 0 || fat > 0) {
                  final brands = (product['brands'] ?? '').toString();
                  final completeness = (product['completeness'] ?? 0.0).toDouble();
                  
                  results.add(ProductSearchResult(
                    productName: productName,
                    brands: brands.isNotEmpty ? brands : null,
                    nutritionPer100g: {
                      'calories': finalCalories,
                      'protein': protein,
                      'carbs': carbs,
                      'fat': fat,
                    },
                    completeness: completeness,
                  ));
                }
              } catch (productError) {
                continue;
              }
            }
            
            if (results.isEmpty) {
              if (attempt < _maxRetries) {
                await Future.delayed(const Duration(seconds: 2));
                return searchProductsOFF(ingredientName, attempt: attempt + 1);
              }
              return null;
            }
            
            results.sort((a, b) => b.completeness.compareTo(a.completeness));
            
            return results;
          }
        } catch (parseError) {
          if (attempt < _maxRetries) {
            await Future.delayed(const Duration(seconds: 2));
            return searchProductsOFF(ingredientName, attempt: attempt + 1);
          }
        }
      } else if (response.statusCode == 429) {
        await Future.delayed(const Duration(seconds: 5));
        
        if (attempt < _maxRetries) {
          return searchProductsOFF(ingredientName, attempt: attempt + 1);
        }
      } else {
        if (attempt < _maxRetries && response.statusCode >= 500) {
          await Future.delayed(const Duration(seconds: 3));
          return searchProductsOFF(ingredientName, attempt: attempt + 1);
        }
      }
    } on http.ClientException catch (e) {
      if (attempt < _maxRetries) {
        await Future.delayed(const Duration(seconds: 2));
        return searchProductsOFF(ingredientName, attempt: attempt + 1);
      }
    } catch (e) {
      if (attempt < _maxRetries) {
        await Future.delayed(const Duration(seconds: 2));
        return searchProductsOFF(ingredientName, attempt: attempt + 1);
      }
    }
    
    return null;
  }

  double _getDoubleValue(Map<String, dynamic> nutriments, List<String> possibleKeys) {
    for (final key in possibleKeys) {
      if (nutriments[key] != null) {
        final value = nutriments[key];
        if (value is num) {
          return value.toDouble();
        } else if (value is String) {
          return double.tryParse(value) ?? 0.0;
        }
      }
    }
    return 0.0;
  }

  bool _areSimilar(String s1, String s2) {
    final clean1 = s1.replaceAll(RegExp(r'[^a-z0-9]'), '').toLowerCase();
    final clean2 = s2.replaceAll(RegExp(r'[^a-z0-9]'), '').toLowerCase();
    
    if (clean2.length < 3) {
      return clean1 == clean2;
    }
    
    if (clean1.contains(clean2) || clean2.contains(clean1)) {
      return true;
    }
    
    if (clean1.length >= 4 && clean2.length >= 4) {
      if (clean1.substring(0, 4) == clean2.substring(0, 4)) {
        return true;
      }
    }
    
    if (clean1.length <= 8 && clean2.length <= 8) {
      final distance = _levenshteinDistance(clean1, clean2);
      final maxLen = clean1.length > clean2.length ? clean1.length : clean2.length;
      final similarity = 1.0 - (distance / maxLen);
      
      if (similarity >= 0.7) {
        return true;
      }
    }
    
    return false;
  }
  
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);
    
    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      
      for (int j = 0; j < s2.length; j++) {
        final cost = s1[i] == s2[j] ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      
      final temp = v0;
      v0 = v1;
      v1 = temp;
    }
    
    return v0[s2.length];
  }
}