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
  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxRetries = 2;

  Future<List<ProductSearchResult>?> searchProductsOFF(String ingredientName, {int attempt = 1}) async {
    try {
      final searchTerms = _prepareSearchTerms(ingredientName);
      
      final queryParams = {
        'search_terms': searchTerms,
        'action': 'process',
        'json': '1',
        'page_size': '50',
        'fields': 'product_name,nutriments,brands,completeness,categories',
        'sort_by': 'unique_scans_n',
        'tagtype_0': 'countries',
        'tag_contains_0': 'contains',
        'tag_0': 'germany',
      };

      final uri = Uri.parse(_offBaseUrl).replace(queryParameters: queryParams);
      
      debugPrint('🔍 Suche nach: "$ingredientName" (Versuch $attempt)');
      debugPrint('📡 URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'KochrezepteApp/1.0 (Mobile)',
          'Accept': 'application/json',
          'Accept-Language': 'de-DE,de;q=0.9,en;q=0.8',
        },
      ).timeout(_timeout);

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          
          final productCount = data['count'] ?? 0;
          debugPrint('📦 Gefunden: $productCount Produkte');
          
          if (productCount == 0 && attempt == 1) {
            debugPrint('⚠️ Keine Ergebnisse, versuche breitere Suche...');
            await Future.delayed(const Duration(milliseconds: 800));
            return searchProductsOFF(ingredientName, attempt: 2);
          }
          
          if (data['products'] != null && (data['products'] as List).isNotEmpty) {
            final productsList = data['products'] as List;
            
            final List<ProductSearchResult> results = [];
            final searchLower = ingredientName.toLowerCase().trim();
            
            for (int i = 0; i < productsList.length && results.length < 10; i++) {
              final product = productsList[i];
              try {
                final productName = (product['product_name'] ?? '').toString().trim();
                
                if (productName.isEmpty) continue;
                
                final productNameLower = productName.toLowerCase();
                
                final relevanceScore = _calculateRelevance(searchLower, productNameLower);
                
                if (relevanceScore < 0.3) continue;
                
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
                    debugPrint('⚠️ Fehler bei kJ Umrechnung: $e');
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
                  
                  debugPrint('✅ Produkt hinzugefügt: $productName (${finalCalories.round()}kcal)');
                }
              } catch (productError) {
                debugPrint('⚠️ Fehler bei Produkt $i: $productError');
                continue;
              }
            }
            
            if (results.isEmpty) {
              debugPrint('❌ Keine verwertbaren Produkte gefunden');
              if (attempt < _maxRetries) {
                await Future.delayed(const Duration(seconds: 1));
                return searchProductsOFF(ingredientName, attempt: attempt + 1);
              }
              return null;
            }
            
            results.sort((a, b) {
              final completenessDiff = b.completeness.compareTo(a.completeness);
              if (completenessDiff != 0) return completenessDiff;
              
              final aHasCalories = a.nutritionPer100g['calories']! > 0 ? 1 : 0;
              final bHasCalories = b.nutritionPer100g['calories']! > 0 ? 1 : 0;
              return bHasCalories.compareTo(aHasCalories);
            });
            
            debugPrint('✨ Zurückgegeben: ${results.length} Produkte');
            return results;
          }
        } catch (parseError) {
          debugPrint('❌ Parse Fehler: $parseError');
          if (attempt < _maxRetries) {
            await Future.delayed(const Duration(seconds: 1));
            return searchProductsOFF(ingredientName, attempt: attempt + 1);
          }
        }
      } else if (response.statusCode == 429) {
        debugPrint('⏳ Rate Limit erreicht, warte...');
        await Future.delayed(const Duration(seconds: 5));
        
        if (attempt < _maxRetries) {
          return searchProductsOFF(ingredientName, attempt: attempt + 1);
        }
      } else {
        debugPrint('❌ HTTP Fehler: ${response.statusCode}');
        if (attempt < _maxRetries && response.statusCode >= 500) {
          await Future.delayed(const Duration(seconds: 2));
          return searchProductsOFF(ingredientName, attempt: attempt + 1);
        }
      }
    } on http.ClientException catch (e) {
      debugPrint('❌ Network Fehler: $e');
      if (attempt < _maxRetries) {
        await Future.delayed(const Duration(seconds: 2));
        return searchProductsOFF(ingredientName, attempt: attempt + 1);
      }
    } catch (e) {
      debugPrint('❌ Unerwarteter Fehler: $e');
      if (attempt < _maxRetries) {
        await Future.delayed(const Duration(seconds: 2));
        return searchProductsOFF(ingredientName, attempt: attempt + 1);
      }
    }
    
    return null;
  }

  String _prepareSearchTerms(String ingredient) {
    String clean = ingredient.toLowerCase().trim();
    
    final synonyms = {
      'mehl': 'weizenmehl OR mehl',
      'zucker': 'zucker OR kristallzucker',
      'öl': 'öl OR speiseöl',
      'reis': 'reis OR basmatireis',
      'nudeln': 'nudeln OR pasta',
      'kartoffeln': 'kartoffeln OR kartoffel',
      'tomaten': 'tomaten OR tomate',
      'zwiebeln': 'zwiebeln OR zwiebel',
    };
    
    return synonyms[clean] ?? clean;
  }

  double _calculateRelevance(String search, String productName) {
    final searchWords = search.split(' ').where((w) => w.length > 2).toList();
    final productWords = productName.split(' ');
    
    if (productName.contains(search)) return 1.0;
    
    if (search.contains(productName)) return 0.9;
    
    int matchCount = 0;
    for (final searchWord in searchWords) {
      for (final productWord in productWords) {
        if (productWord.contains(searchWord) || searchWord.contains(productWord)) {
          matchCount++;
          break;
        }
      }
    }
    
    if (searchWords.isEmpty) return 0.5;
    
    final wordMatchRatio = matchCount / searchWords.length;
    
    final clean1 = search.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final clean2 = productName.replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    if (clean1.length >= 4 && clean2.length >= 4) {
      if (clean1.substring(0, 4) == clean2.substring(0, 4)) {
        return (wordMatchRatio + 0.8) / 2;
      }
    }
    
    return wordMatchRatio;
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