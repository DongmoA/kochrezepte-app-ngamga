import 'package:flutter/material.dart';
import 'package:kochrezepte_app/supabase/supabase_client.dart';
import 'pages/register_page.dart';
import 'pages/login_page.dart';
import 'pages/Recipe/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseClientManager.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RecipeShare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE65100)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}