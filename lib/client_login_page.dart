import 'package:flutter/material.dart';

class ClientLoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    debugPrint('ClientLoginPage carregada');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Cliente'),
      ),
      body: Center(
        child: Text('Página de Login do Cliente'),
      ),
    );
  }
}
