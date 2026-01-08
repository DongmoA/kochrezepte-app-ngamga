
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientManager {
  static late final SupabaseClient client;

  static Future<void> initialize() async {
    const supabaseUrl = 'https://vfsjphaumjcpusuqakmv.supabase.co';
    const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    


    client = Supabase.instance.client;
  }
}
