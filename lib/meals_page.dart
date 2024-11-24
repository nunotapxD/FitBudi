import 'package:flutter/material.dart';

class MealsPage extends StatelessWidget {
  const MealsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Meals"),
      ),
      body: Center(
        child: Text("Welcome to the Meals Page!"),
      ),
    );
  }
}