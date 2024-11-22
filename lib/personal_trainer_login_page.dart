import 'package:flutter/material.dart';

class PersonalTrainerLoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    debugPrint('PersonalTrainerLoginPage carregada');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Personal Trainer'),
      ),
      body: Center(
        child: Text('Página de Login do Personal Trainer'),
      ),
    );
  }
}
