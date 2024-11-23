import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'firebase_options.dart'; // Import Firebase options

import 'login.dart'; // Import the login selection page
import 'client_dashboard_page.dart'; // Import the client dashboard page
import 'admin_dashboard.dart'; // Import the admin dashboard page

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // Use platform-specific options
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e'); // Print errors if initialization fails
  }

  runApp(MyApp()); // Run the app
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitBudi',
      initialRoute: '/login', // Set the initial route to the login page
      routes: {
        '/login': (context) => LoginSelectionPage(),
        '/dashboard': (context) => ClientDashboardPage(),
        '/adminDashboard': (context) => AdminDashboardPage(), // Add admin dashboard route
        // Add more routes as needed
      },
    );
  }
}
