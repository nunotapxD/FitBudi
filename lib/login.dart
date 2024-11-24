import 'login_register.dart'; // Import ClientRegisterPage
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/material.dart';
import 'client_dashboard_page.dart'; // Import ClientDashboardPage
import 'admin_dashboard.dart'; // Import AdminDashboardPage

class LoginSelectionPage extends StatefulWidget {
  const LoginSelectionPage({super.key});

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
        const SnackBar(content: Text('Por favor, insira e-mail e senha válidos')),
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

      // Get the user's role from Firestore
      final userId = userCredential.user?.uid;
      if (userId == null) throw FirebaseAuthException(code: "user-not-found");

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não encontrado no banco de dados')),
        );
        return;
      }

      final userData = userDoc.data();
      final role = userData?['role'] ?? 'client'; // Default role is 'client'

      // Navigate based on role
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboardPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ClientDashboardPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase authentication errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer login: ${e.message}')),
      );
    } catch (e) {
      // Handle other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Properly close the `setState` block
      });
    }
  }
}
