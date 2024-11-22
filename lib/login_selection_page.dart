import 'client_register_page.dart'; // Import ClientRegisterPage
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'client_dashboard_page.dart';  // Assuming you have a ClientDashboardPage

class LoginSelectionPage extends StatefulWidget {
  @override
  _LoginSelectionPageState createState() => _LoginSelectionPageState();
}

class _LoginSelectionPageState extends State<LoginSelectionPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordFieldVisible = false;
  bool _isEmailValidated = false; // Track if the email is validated
  bool _isLoading = false; // For showing loading spinner during authentication

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: 400), // Max width for form
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email input field
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: const OutlineInputBorder(),
                          suffixIcon: !_isEmailValidated
                              ? IconButton(
                                  icon: Icon(Icons.arrow_forward),
                                  onPressed: () {
                                    setState(() {
                                      _isEmailValidated = true;
                                      _isPasswordFieldVisible = true; // Show password field
                                    });
                                  },
                                )
                              : null, // Remove the arrow after email is validated
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Password field, will appear after user clicks the arrow in the email field
                      if (_isPasswordFieldVisible)
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.arrow_forward),
                              onPressed: () async {
                                // Authenticate with Firebase
                                await _authenticateUser();
                              },
                            ),
                          ),
                          obscureText: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Link for registering a new account
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ClientRegisterPage()),
                    );
                  },
                  child: const Text(
                    'Não tem uma conta? Registre-se',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
                const SizedBox(height: 16),
                // Space PT link (Admin dashboard)
                TextButton(
                  onPressed: () {
                    debugPrint('Navigating to Space PT (Admin Dashboard)');
                    // Replace this with actual navigation for the admin dashboard
                  },
                  child: const Text(
                    'Space PT',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Function to authenticate user with Firebase
  Future<void> _authenticateUser() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, insira e-mail e senha válidos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // If successful, navigate to the client dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ClientDashboardPage()),
      );
    } on FirebaseAuthException catch (e) {
      // Handle Firebase authentication errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer login: ${e.message}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
