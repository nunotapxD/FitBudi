import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Função para fazer logout
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/loginSelection');
    } catch (e) {
      print("Error logging out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out. Please try again.")),
      );
    }
  }

  // Função para redefinir senha
  Future<void> _resetPassword(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password reset email sent.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No user is logged in.")),
        );
      }
    } catch (e) {
      print("Error resetting password: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error resetting password. Please try again.")),
      );
    }
  }

  // Função para atualizar o nome da conta
  Future<void> _updateDisplayName(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Update Display Name"),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: "New Display Name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    await user?.updateDisplayName(newName);
                    await user?.reload();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Display name updated successfully.")),
                    );
                  } catch (e) {
                    print("Error updating display name: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error updating display name. Please try again.")),
                    );
                  }
                }
                Navigator.of(context).pop();
              },
              child: Text("Save"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
        child: ListView(
          children: [
            ListTile(
              title: Text("Logout"),
              leading: Icon(Icons.exit_to_app),
              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
            ),
            ListTile(
              title: Text("Reset Password"),
              leading: Icon(Icons.lock_reset),
              onTap: () => _resetPassword(context),
            ),
            ListTile(
              title: Text("Update Display Name"),
              leading: Icon(Icons.person),
              onTap: () => _updateDisplayName(context),
            ),
          ],
        ),
      ),
    );
  }
}
