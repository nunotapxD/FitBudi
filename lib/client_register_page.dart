import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientRegisterPage extends StatefulWidget {
  @override
  _ClientRegisterPageState createState() => _ClientRegisterPageState();
}

class _ClientRegisterPageState extends State<ClientRegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _registerClient() async {
    // Exibindo no console se a função foi chamada
    debugPrint("Botão 'Registrar' pressionado");

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Ativa o estado de carregamento
      });

      try {
        // Exibe uma mensagem de depuração antes de tentar registrar
        debugPrint("Tentando registrar usuário com e-mail: ${_emailController.text}");
        
        // Registra o cliente no Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        debugPrint("Usuário registrado com sucesso: ${userCredential.user?.email}");
        
        // Exibe mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário registrado com sucesso!')),
        );

        // Navegação para a página de login ou outra página após o registro
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => LoginPage()),
        // );
      } on FirebaseAuthException catch (e) {
        // Exibe a mensagem de erro
        setState(() {
          _errorMessage = e.message;
        });
        debugPrint("Erro ao registrar usuário: ${e.message}");
      } finally {
        setState(() {
          _isLoading = false; // Finaliza o carregamento
        });
      }
    } else {
      // Mensagem de depuração caso o formulário não seja válido
      debugPrint("Formulário não é válido. Validação falhou.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Cliente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Campo de E-mail
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o e-mail';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Campo de Senha
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a senha';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Campo de Confirmar Senha
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirmar Senha'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, confirme a senha';
                  }
                  if (value != _passwordController.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Indicador de Carregamento
              if (_isLoading)
                CircularProgressIndicator(), // Exibe o carregamento enquanto registra
              
              // Botão de Registro
              if (!_isLoading)
                ElevatedButton(
                  onPressed: _registerClient,
                  child: Text('Registrar'),
                ),
              
              // Exibição de erro
              if (_errorMessage != null) ...[
                SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
