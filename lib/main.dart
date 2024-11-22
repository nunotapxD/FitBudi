import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'login_selection_page.dart';

// Add the FirebaseOptions for web initialization
const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyARTGJEQOoeMH8dyDPJ6dBg6LqzICKdC6Y",  // Replace with your actual API key
  authDomain: "fitbudi-4c6da.firebaseapp.com",  // Replace with your actual authDomain
  projectId: "fitbudi-4c6da",  // Replace with your actual projectId
  storageBucket: "fitbudi-4c6da.firebasestorage.app",  // Replace with your actual storageBucket
  messagingSenderId: "1094621998423",  // Replace with your actual messagingSenderId
  appId: "1:1094621998423:web:1c2d49459341583cf9e212",  // Replace with your actual appId
  measurementId: "G-KMZYMH8JKF",  // Replace with your actual measurementId
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and check if successful
  await Firebase.initializeApp(options: firebaseOptions).catchError((e) {
    debugPrint('Error initializing Firebase: $e');
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitBudi',
      // Use FutureBuilder to handle Firebase initialization status
      home: FutureBuilder(
        future: Firebase.initializeApp(options: firebaseOptions),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text(
                    'Erro ao iniciar o Firebase, tente novamente mais tarde',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                ),
              );
            }
            return LoginSelectionPage(); // Firebase initialized successfully, show LoginSelectionPage
          }
          // While Firebase is initializing, show a loading spinner
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
      routes: {
        '/loginSelection': (context) => LoginSelectionPage(),
        // Define any other routes like '/clientDashboard', '/clientRegister' as necessary
      },
    );
  }
}
