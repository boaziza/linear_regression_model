import 'package:flutter/material.dart';
import 'package:flutter_app/screen/prediction_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Youth Wage Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: const Color(0xFF111111)),
      ),
      home: const PredictionPage(),
    );
  }
}
