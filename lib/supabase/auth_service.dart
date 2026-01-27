
import 'package:flutter/widgets.dart';
import 'package:kochrezepte_app/supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

class AuthService {
  final supaClient = SupabaseClientManager.client;

  // Prüfen ob der Benutzername bereits vergeben ist
  // Prüfen ob der Benutzername bereits vergeben ist
  Future<bool?> isUsernameTaken(String username) async {
    try {
      final result = await supaClient
          .from('profiles')
          .select('username')
          .eq('username', username)
          .maybeSingle();
      
      return result != null;
    } catch (e) {
      debugPrint('Fehler bei der Überprüfung des Benutzernamens: $e');
      // Rückgabe null bei Fehler, um anzuzeigen, dass die Prüfung fehlgeschlagen ist
      return null;
    }
  }
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    String? dietPreference,
  }) async {
    try {
      final response = await supaClient.auth.signUp(
        email: email,
        password: password,
      );

      
      if (response.user != null) {
        await supaClient.from('profiles').insert({
          'id': response.user!.id,
          'username': username,
          'diet_preference': dietPreference,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      return response;
    } on AuthException catch (e) {
      throw Exception('Registrierung fehlgeschlagen: ${e.message}');
    } catch (e) {
      throw Exception('Profil-Erstellung fehlgeschlagen: $e');
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

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final userId = supaClient.auth.currentUser?.id;
      if (userId == null) return null;

      final data = await supaClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return data;
    } catch (e) {
      debugPrint('Error getProfile: $e');
      return null;
    }
  }

  
  Future<void> updateProfile({
    required String username,
    String? dietPreference,
  }) async {
    try {
      final userId = supaClient.auth.currentUser?.id;
      if (userId == null) throw Exception('Nicht angemeldet');

      await supaClient.from('profiles').upsert({
        'id': userId,
        'username': username,
        'diet_preference': dietPreference,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Profil-Update fehlgeschlagen: $e');
    }

  }
  
  Future<void> deleteAccount() async {
    try {
      final userId = supaClient.auth.currentUser?.id;
      if (userId == null) throw Exception('Nicht angemeldet');

      
      await supaClient.from('profiles').delete().eq('id', userId);

      
      await supaClient.auth.signOut();
    } catch (e) {
      throw Exception('Konto löschen fehlgeschlagen: $e');
    }
  }

}
