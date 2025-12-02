import 'package:flutter/material.dart';
import 'package:kochrezepte_app/pages/home.dart';
import 'package:kochrezepte_app/supabase/auth_service.dart';
import 'package:kochrezepte_app/supabase/supabase_client.dart';

Future<void> main()  async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseClientManager.initialize();
  // Test 
  final authService = AuthService();
  await authService.printUsers();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Korezept App',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
