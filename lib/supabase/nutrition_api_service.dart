import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ProductSearchResult {
  final String productName;
  final String? brands;
  final Map<String, double> nutritionPer100g;
  final double completeness;
  final String source; // 'USDA' oder 'Generic'

  ProductSearchResult({
    required this.productName,
    this.brands,
    required this.nutritionPer100g,
    required this.completeness,
    this.source = 'USDA',
  });
}

class NutritionApiService {
  // USDA FoodData Central API
  static const String _usdaBaseUrl = 'https://api.nal.usda.gov/fdc/v1/foods/search';
  static const String _usdaApiKey = 'uJsCUsiiGHXNNNadhlAJp5eWxkxHRjAlwHVB22kx'; 
  
  // LibreTranslate API für automatische Übersetzung
  static const String _translateBaseUrl = 'https://libretranslate.com/translate';
  
  // MyMemory API als Fallback (kostenlos, kein Key nötig)
  static const String _myMemoryBaseUrl = 'https://api.mymemory.translated.net/get';
  
  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _translateTimeout = Duration(seconds: 4);
  static const int _maxRetries = 2;
  
  // Cache für Übersetzungen
  final Map<String, String> _translationCache = {};

  Future<List<ProductSearchResult>?> searchProductsOFF(String ingredientName, {int attempt = 1}) async {
    try {
      // Übersetze deutsche Zutaten ins Englische (automatisch)
      final searchTerm = await _translateToEnglishAuto(ingredientName.toLowerCase().trim());
      
      debugPrint('🔍 USDA Suche: "$ingredientName" → "$searchTerm"');
      
      final queryParams = {
        'api_key': _usdaApiKey,
        'query': searchTerm,
        'pageSize': '25',
        'dataType': 'Foundation,SR Legacy', // Grundlegende Lebensmittel
      };

      final uri = Uri.parse(_usdaBaseUrl).replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      debugPrint('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          
          final foods = data['foods'] as List?;
          
          if (foods == null || foods.isEmpty) {
            debugPrint('❌ Keine Ergebnisse gefunden');
            if (attempt < _maxRetries) {
              await Future.delayed(const Duration(seconds: 1));
              return searchProductsOFF(ingredientName, attempt: attempt + 1);
            }
            return null;
          }
          
          debugPrint('📦 Gefunden: ${foods.length} Lebensmittel');
          
          final List<ProductSearchResult> results = [];
          final List<Map<String, dynamic>> foodsToTranslate = [];
          
          // Sammle alle Lebensmittel mit Nährwerten
          for (int i = 0; i < foods.length && foodsToTranslate.length < 10; i++) {
            final food = foods[i];
            try {
              final description = (food['description'] ?? '').toString().trim();
              
              if (description.isEmpty) continue;
              
              // Hole Nährwerte
              final foodNutrients = food['foodNutrients'] as List?;
              if (foodNutrients == null) continue;
              
              double calories = 0;
              double protein = 0;
              double carbs = 0;
              double fat = 0;
              
              for (final nutrient in foodNutrients) {
                final nutrientNumber = nutrient['nutrientNumber']?.toString() ?? '';
                final value = (nutrient['value'] ?? 0).toDouble();
                
                switch (nutrientNumber) {
                  case '208': // Energy (kcal)
                    calories = value;
                    break;
                  case '203': // Protein
                    protein = value;
                    break;
                  case '205': // Carbohydrates
                    carbs = value;
                    break;
                  case '204': // Total lipid (fat)
                    fat = value;
                    break;
                }
              }
              
              // Nur hinzufügen wenn wir Nährwerte haben
              if (calories > 0 || protein > 0 || carbs > 0 || fat > 0) {
                final dataType = food['dataType']?.toString() ?? '';
                final completeness = _calculateCompleteness(calories, protein, carbs, fat);
                
                foodsToTranslate.add({
                  'description': description,
                  'dataType': dataType,
                  'completeness': completeness,
                  'calories': calories,
                  'protein': protein,
                  'carbs': carbs,
                  'fat': fat,
                });
              }
            } catch (e) {
              debugPrint('⚠️ Fehler bei Food $i: $e');
              continue;
            }
          }
          
          // Übersetze alle Beschreibungen PARALLEL
          debugPrint('🔄 Übersetze ${foodsToTranslate.length} Ergebnisse parallel...');
          final translationFutures = foodsToTranslate.map((foodData) {
            return _translateToGerman(foodData['description'] as String);
          }).toList();
          
          final germanDescriptions = await Future.wait(translationFutures);
          
          // Erstelle ProductSearchResults mit übersetzten Namen
          for (int i = 0; i < foodsToTranslate.length; i++) {
            final foodData = foodsToTranslate[i];
            final germanDescription = germanDescriptions[i];
            
            results.add(ProductSearchResult(
              productName: germanDescription,
              brands: (foodData['dataType'] as String).isNotEmpty 
                  ? 'USDA - ${foodData['dataType']}' 
                  : 'USDA',
              nutritionPer100g: {
                'calories': foodData['calories'] as double,
                'protein': foodData['protein'] as double,
                'carbs': foodData['carbs'] as double,
                'fat': foodData['fat'] as double,
              },
              completeness: foodData['completeness'] as double,
              source: 'USDA',
            ));
            
            debugPrint('✅ ${i+1}/${foodsToTranslate.length}: $germanDescription');
          }
          
          if (results.isEmpty) {
            debugPrint('❌ Keine verwertbaren Lebensmittel');
            if (attempt < _maxRetries) {
              await Future.delayed(const Duration(seconds: 1));
              return searchProductsOFF(ingredientName, attempt: attempt + 1);
            }
            return null;
          }
          
          // Sortiere nach Vollständigkeit
          results.sort((a, b) => b.completeness.compareTo(a.completeness));
          
          debugPrint('✨ Zurückgegeben: ${results.length} Lebensmittel');
          return results;
          
        } catch (parseError) {
          debugPrint('❌ Parse Fehler: $parseError');
          if (attempt < _maxRetries) {
            await Future.delayed(const Duration(seconds: 1));
            return searchProductsOFF(ingredientName, attempt: attempt + 1);
          }
        }
      } else if (response.statusCode == 429) {
        debugPrint('⏳ Rate Limit erreicht');
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

  /// Automatische Übersetzung DE→EN mit LibreTranslate und MyMemory
  Future<String> _translateToEnglishAuto(String german) async {
    final cleanGerman = german.toLowerCase().trim();
    
    // Prüfe Cache
    final cacheKey = 'de_en_$cleanGerman';
    if (_translationCache.containsKey(cacheKey)) {
      debugPrint('📝 Cache DE→EN: "$cleanGerman" → "${_translationCache[cacheKey]}"');
      return _translationCache[cacheKey]!;
    }
    
    // Versuch 1: LibreTranslate
    try {
      debugPrint('🌐 LibreTranslate DE→EN: "$cleanGerman"');
      
      final response = await http.post(
        Uri.parse(_translateBaseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'q': cleanGerman,
          'source': 'de',
          'target': 'en',
          'format': 'text',
        }),
      ).timeout(_translateTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translated = (data['translatedText'] ?? '').toString().toLowerCase().trim();
        
        if (translated.isNotEmpty && translated != cleanGerman) {
          debugPrint('✅ LibreTranslate übersetzt DE→EN: "$cleanGerman" → "$translated"');
          _translationCache[cacheKey] = translated;
          return translated;
        }
      }
      debugPrint('⚠️ LibreTranslate fehlgeschlagen, versuche MyMemory...');
    } catch (e) {
      debugPrint('⚠️ LibreTranslate Fehler: $e, versuche MyMemory...');
    }
    
    // Versuch 2: MyMemory API als Fallback
    try {
      debugPrint('🌐 MyMemory DE→EN: "$cleanGerman"');
      
      final uri = Uri.parse(_myMemoryBaseUrl).replace(queryParameters: {
        'q': cleanGerman,
        'langpair': 'de|en',
      });
      
      final response = await http.get(uri).timeout(_translateTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translated = (data['responseData']?['translatedText'] ?? '').toString().toLowerCase().trim();
        
        if (translated.isNotEmpty && translated != cleanGerman) {
          debugPrint('✅ MyMemory übersetzt DE→EN: "$cleanGerman" → "$translated"');
          _translationCache[cacheKey] = translated;
          return translated;
        }
      }
      debugPrint('⚠️ MyMemory fehlgeschlagen');
    } catch (e) {
      debugPrint('⚠️ MyMemory Fehler: $e');
    }
    
    // Fallback: Original behalten
    debugPrint('⚠️ Keine Übersetzung möglich, behalte Original: "$cleanGerman"');
    return cleanGerman;
  }

  /// Automatische Übersetzung EN→DE mit LibreTranslate API und MyMemory Fallback
  Future<String> _translateToGerman(String english) async {
    final cleanEnglish = english.toLowerCase().trim();
    
    // Prüfe Cache
    final cacheKey = 'en_de_$cleanEnglish';
    if (_translationCache.containsKey(cacheKey)) {
      debugPrint('📝 Cache EN→DE: "$cleanEnglish" → "${_translationCache[cacheKey]}"');
      return _translationCache[cacheKey]!;
    }
    
    // Versuch 1: LibreTranslate
    try {
      final response = await http.post(
        Uri.parse(_translateBaseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'q': cleanEnglish,
          'source': 'en',
          'target': 'de',
          'format': 'text',
        }),
      ).timeout(_translateTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translated = (data['translatedText'] ?? '').toString().trim();
        
        if (translated.isNotEmpty && translated != cleanEnglish) {
          _translationCache[cacheKey] = translated;
          return translated;
        }
      }
    } catch (e) {
      // Fehler stillschweigend ignorieren, versuche MyMemory
    }
    
    // Versuch 2: MyMemory API als Fallback
    try {
      final uri = Uri.parse(_myMemoryBaseUrl).replace(queryParameters: {
        'q': cleanEnglish,
        'langpair': 'en|de',
      });
      
      final response = await http.get(uri).timeout(_translateTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translated = (data['responseData']?['translatedText'] ?? '').toString().trim();
        
        if (translated.isNotEmpty && translated != cleanEnglish) {
          _translationCache[cacheKey] = translated;
          return translated;
        }
      }
    } catch (e) {
      // Fehler stillschweigend ignorieren
    }
    
    // Fallback: Original behalten (Englisch)
    return cleanEnglish;
  }

  double _calculateCompleteness(double calories, double protein, double carbs, double fat) {
    int fieldsFilled = 0;
    if (calories > 0) fieldsFilled++;
    if (protein > 0) fieldsFilled++;
    if (carbs > 0) fieldsFilled++;
    if (fat > 0) fieldsFilled++;
    
    return (fieldsFilled / 4.0) * 100;
  }
}