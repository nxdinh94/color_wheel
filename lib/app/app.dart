import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';

class HueWheelApp extends StatelessWidget {
  const HueWheelApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Hue Wheel',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F5F0),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF363638),
        surface: const Color(0xFFF7F5F0),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFF2A2928),
          fontSize: 39,
          fontWeight: FontWeight.w300,
          letterSpacing: -1.3,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF2A2928),
          fontSize: 23,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(color: Color(0xFF77736D), fontSize: 15),
      ),
    ),
    home: const HomeScreen(),
  );
}
