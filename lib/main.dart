import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'login_selection_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase inicializado');
  } catch (e) {
    debugPrint('Erro ao inicializar Firebase: $e');
  }
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitBudi',
      home: LoginSelectionPage(),
    );
  }
}
