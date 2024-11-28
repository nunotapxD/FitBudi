import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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

  Future<void> _updateDisplayName(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No user is logged in.")),
      );
      return;
    }

    nameController.text = user.displayName ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Update Display Name"),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: "New Display Name",
              hintText: "Enter your new display name",
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Display name cannot be empty.")),
                  );
                  return;
                }

                try {
                  // Update in Firebase Authentication
                  await user.updateDisplayName(newName);
                  await user.reload();

                  // Update in Firestore Database with 'name' field
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'name': newName,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Display name updated successfully.")),
                  );
                } catch (e) {
                  print("Error updating display name: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error updating display name. Please try again.")),
                  );
                }
              },
              child: Text("Save"),
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
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                title: Text("Logout"),
                leading: Icon(Icons.exit_to_app),
                onTap: () => _logout(context),
              ),
            ),
            SizedBox(height: 10),
            Card(
              child: ListTile(
                title: Text("Reset Password"),
                leading: Icon(Icons.lock_reset),
                onTap: () => _resetPassword(context),
              ),
            ),
            SizedBox(height: 10),
            Card(
              child: ListTile(
                title: Text("Update Display Name"),
                leading: Icon(Icons.person),
                onTap: () => _updateDisplayName(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}