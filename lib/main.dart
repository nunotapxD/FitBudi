import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Adicione esta importação
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';

// Import das páginas
import 'login.dart';
import 'admin_dashboard.dart';
import 'client_dashboard_page.dart';
import 'chat/chat_list_page.dart';
import 'settings_page.dart';
import 'calendar_page.dart';
import 'videos_page.dart';
import 'meals_page.dart';

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
      
      // Configuração de localização
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
      
      // Configuração do tema
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

      // Gerenciador de rotas
      onGenerateRoute: (settings) {
        print('Attempting to generate route: ${settings.name}');
        
        // Verificar o usuário atual
        final auth = FirebaseAuth.instance;
        final user = auth.currentUser;
        
        switch (settings.name) {
          case '/':
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginSelectionPage());
            
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const ClientDashboardPage());
            
          case '/adminDashboard':
            return MaterialPageRoute(builder: (_) => const AdminDashboardPage());
            
          case '/chat':
            return MaterialPageRoute(builder: (_) => const ChatListPage());
            
          case '/calendar':
            if (user != null) {
              return MaterialPageRoute(
                builder: (_) => CalendarPage(
                  userId: user.uid,
                  isAdmin: false, // Cliente acessando direto pelo menu
                ),
              );
            } else {
              return MaterialPageRoute(builder: (_) => const LoginSelectionPage());
            }
            
          case '/meals':
            return MaterialPageRoute(builder: (_) => const MealsPage());
            
          case '/videos':
            return MaterialPageRoute(builder: (_) => const VideosPage());
            
          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsPage());
            
          default:
            // Página 404
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Página não encontrada')),
                body: const Center(
                  child: Text('A página que você procura não existe.'),
                ),
              ),
            );
        }
      },
      
      // Rota inicial
      initialRoute: '/login',
    );
  }
}