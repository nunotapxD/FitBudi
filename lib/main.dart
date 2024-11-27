import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Page imports
import 'login.dart';
import 'admin_dashboard.dart';
import 'client_dashboard_page.dart';
import 'chat/chat_list_page.dart';
import 'settings_page.dart';
import 'calendar_page.dart';
import 'videos_page.dart';
import 'profile_page.dart';
import 'meals_page.dart';
import 'client_workout_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitBudi',
      debugShowCheckedModeBanner: false,

      // Localization settings
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('pt', 'BR'),

      // Theme settings
      theme: ThemeData(
        primaryColor: Colors.deepPurple,
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Authentication and routing setup
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (userSnapshot.hasData && userSnapshot.data != null) {
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  final role = userData?['role'] as String?;

                  if (role == 'admin') {
                    return const AdminDashboardPage();
                  } else {
                    return const ClientDashboardPage();
                  }
                }

                return const LoginSelectionPage();
              },
            );
          }

          return const LoginSelectionPage();
        },
      ),

      onGenerateRoute: (settings) {
        final auth = FirebaseAuth.instance;
        final user = auth.currentUser;

        // Authentication check for protected routes
        bool requiresAuth = settings.name != '/login' && 
                          settings.name != '/register' && 
                          settings.name != '/';

        if (requiresAuth && user == null) {
          return MaterialPageRoute(builder: (_) => const LoginSelectionPage());
        }

        switch (settings.name) {
          case '/':
          case '/login':
            if (user != null) {
              return MaterialPageRoute(builder: (_) => const ClientDashboardPage());
            }
            return MaterialPageRoute(builder: (_) => const LoginSelectionPage());

          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const ClientDashboardPage());

          case '/adminDashboard':
            return MaterialPageRoute(builder: (_) => const AdminDashboardPage());
     
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfilePage());

          case '/chat':
            return MaterialPageRoute(builder: (_) => const ChatListPage());

          case '/calendar':
            return MaterialPageRoute(
              builder: (_) => CalendarPage(
                userId: user!.uid,
                isAdmin: false,
              ),
            );

          case '/meals':
            return MaterialPageRoute(builder: (_) => const MealsPage());

          case '/videos':
            return MaterialPageRoute(builder: (_) => const VideosPage());

          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsPage());

          case '/workouts':
            return MaterialPageRoute(builder: (_) => const ClientWorkoutPage());

          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Página não encontrada')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Página não encontrada',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            _,
                            user != null ? '/dashboard' : '/login',
                          );
                        },
                        child: const Text('Voltar para página inicial'),
                      ),
                    ],
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}