import 'package:flutter/material.dart';
import 'personal_trainer_login_page.dart';
import 'client_login_page.dart';
import 'client_register_page.dart';  // Importando a página de registro do Cliente

class LoginSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Verifique se a tela de seleção está sendo carregada
    debugPrint('LoginSelectionPage construída');
    
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
            // Botão para Login Personal Trainer
            ElevatedButton(
              onPressed: () {
                // Verifique se a navegação está sendo chamada corretamente
                debugPrint('Navegando para PersonalTrainerLoginPage');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PersonalTrainerLoginPage()),
                );
              },
              child: Text('Login como Personal Trainer'),
            ),
            SizedBox(height: 16),
            // Botão para Login Cliente
            ElevatedButton(
              onPressed: () {
                // Verifique se a navegação está sendo chamada corretamente
                debugPrint('Navegando para ClientLoginPage');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ClientLoginPage()),
                );
              },
              child: Text('Login como Cliente'),
            ),
            SizedBox(height: 16),
            // Botão para Registro Cliente
            ElevatedButton(
              onPressed: () {
                // Verifique se a navegação está sendo chamada corretamente
                debugPrint('Navegando para ClientRegisterPage');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ClientRegisterPage()),  // Navega para a página de registro do cliente
                );
              },
              child: Text('Registrar como Cliente'),
            ),
          ],
        ),
      ),
    );
  }
}
