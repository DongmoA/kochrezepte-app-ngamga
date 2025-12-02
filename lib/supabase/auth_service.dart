import 'package:flutter/widgets.dart';
import 'package:kochrezepte_app/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Nécessaire pour PostgrestException

class AuthService {
  final supaClient = SupabaseClientManager.client;

  // Méthode pour récupérer et afficher les users
  Future<void> printUsers() async {
    try {
      // 1. On attend directement le résultat du select()
      // Plus besoin de .execute()
      final List<dynamic> data = await supaClient
          .from('users')
          .select();

      // 2. Conversion des données (Supabase renvoie une List<dynamic> par défaut)
      final users = List<Map<String, dynamic>>.from(data);

      // Afficher chaque utilisateur dans la console
      for (var user in users) {
        debugPrint('ID: ${user['id']}, Username: ${user['username']}, Email: ${user['email']}');
      }

    } on PostgrestException catch (error) {
      // 3. Gestion des erreurs via try/catch
      debugPrint('Erreur Supabase: ${error.message}');
    } catch (e) {
      // Autres erreurs (ex: pas d'internet)
      debugPrint('Erreur inattendue: $e');
    }
  }
}