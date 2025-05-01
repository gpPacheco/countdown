import 'package:flutter/material.dart';
import 'pages/countdown_list_screen.dart'; // Verifique este caminho

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countdown Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const CountdownListScreen(), // Aqui está o uso da classe
    );
  }
}
