import 'package:flutter/material.dart';
import 'package:kochrezepte_app/supabase/supabase_client.dart';
import 'pages/Recipe/recipe_home_page.dart'; 

void main() async {
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
        primarySwatch: Colors.orange,
      ),
      home: const RecipeHomePage(),
    );
  }
}