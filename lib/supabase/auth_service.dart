import 'package:kochrezepte_app/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Nécessaire pour PostgrestException

class AuthService {
  final SupaClient = SupabaseClientManager.client;

  // Méthode pour récupérer et afficher les users
  Future<void> printUsers() async {
    try {
      // 1. On attend directement le résultat du select()
      // Plus besoin de .execute()
      final List<dynamic> data = await SupaClient
          .from('users')
          .select();

      // 2. Conversion des données (Supabase renvoie une List<dynamic> par défaut)
      final users = List<Map<String, dynamic>>.from(data);

      // Afficher chaque utilisateur dans la console
      for (var user in users) {
        print('ID: ${user['id']}, Username: ${user['username']}, Email: ${user['email']}');
      }

    } on PostgrestException catch (error) {
      // 3. Gestion des erreurs via try/catch
      print('Erreur Supabase: ${error.message}');
    } catch (e) {
      // Autres erreurs (ex: pas d'internet)
      print('Erreur inattendue: $e');
    }
  }
   Future<AuthResponse> signUp({
    required String email,
    required String password,
   }) async {
    try {
    final response = await SupaClient.auth.signUp(
      email : email,
      password : password
    );
    return response;
    } on AuthException catch(e){
      throw Exception('Registrierung fehlgeschlagen: ${e.message}');
    }
   }
   // ANMELDUNG (signIn)
Future<AuthResponse> signIn({
  required String email,
  required String password,
}) async {
  try {
    final response = await SupaClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  } on AuthException catch (e) {
    throw Exception('Anmeldung fehlgeschlagen: ${e.message}');
  }
}
  
// ABMELDUNG (signOut)
Future<void> signOut() async {
  try {
    await SupaClient.auth.signOut();
  } on AuthException catch (e) {
    throw Exception('Abmeldung fehlgeschlagen: ${e.message}');
  }
}
}