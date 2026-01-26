
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientManager {
  static late final SupabaseClient client;

  static Future<void> initialize() async {

    await dotenv.load(fileName: ".env");

    final supabaseUrl = dotenv.env['SUPABASE_URL']?? '';
    final supabaseKey = dotenv.env['SUPABASE_KEY'] ?? '';

     if (supabaseKey.isEmpty) {
      throw Exception('SUPABASE_KEY nicht in .env gefunden!');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    


    client = Supabase.instance.client;
  }
}
