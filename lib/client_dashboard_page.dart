import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientDashboardPage extends StatelessWidget {
  // This function will log out the user from Firebase
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); // Log the user out
      // After logout, navigate to the LoginSelectionPage
      Navigator.pushReplacementNamed(context, '/loginSelection'); // Use /loginSelection route to navigate
    } catch (e) {
      // Handle any error that occurs during logout
      print("Error logging out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),  // Logout icon
            onPressed: () => _logout(context), // Call logout function when clicked
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome to the Client Dashboard'),
      ),
    );
  }
}
