
import 'package:flutter/cupertino.dart';
import 'package:kochrezepte_app/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Nécessaire pour PostgrestException

class AuthService {
  final supaClient = SupabaseClientManager.client;


  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supaClient.auth.signUp(
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
      final response = await supaClient.auth.signInWithPassword(
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
      await supaClient.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Abmeldung fehlgeschlagen: ${e.message}');
    }
  }
 
 // take the user id of the currently logged in user

 String getCurrentUserId() {
  final id = supaClient.auth.currentUser?.id;
 
 
  if (id == null) {
    // that means user is not logged in
    throw Exception("User is not authenticated. Cannot perform rating operation.");
  }
  return id;
}

}
