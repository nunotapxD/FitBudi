import 'package:flutter/material.dart';
import 'personal_trainer_login_page.dart';
import 'client_login_page.dart';  // Certifique-se de que esse arquivo existe

class LoginSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleção de Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navegar para a página de login do Personal Trainer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PersonalTrainerLoginPage()),
                );
              },
              child: Text('Login como Personal Trainer'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navegar para a página de login do Cliente
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ClientLoginPage()),  // Certifique-se de que a ClientLoginPage está configurada
                );
              },
              child: Text('Login como Cliente'),
            ),
          ],
        ),
      ),
    );
  }
}
