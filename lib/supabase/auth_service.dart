import 'package:flutter/widgets.dart';
import 'package:kochrezepte_app/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get SupaClient => SupabaseClientManager.client;

  // Méthode pour récupérer et afficher les users
  Future<void> printUsers() async {
    try {
      final List<dynamic> data = await SupaClient.from('users').select();

      final users = List<Map<String, dynamic>>.from(data);

      for (var user in users) {
        debugPrint('ID: ${user['id']}, Username: ${user['username']}, Email: ${user['email']}');
      }
    } on PostgrestException catch (error) {
      debugPrint('Erreur Supabase: ${error.message}');
    } catch (e) {
      debugPrint('Erreur inattendue: $e');
    }
  }

  // REGISTRIERUNG (signUp)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupaClient.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
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