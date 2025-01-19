import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finans Takip',
      theme: ThemeData.light(), // Açık tema
      darkTheme: ThemeData.dark(), // Koyu tema
      themeMode: ThemeMode.system, // Sistem teması
      home: HomeScreen(),
    );
  }
}