import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';

// Importação das páginas
import 'login.dart';
import 'admin_dashboard.dart';
import 'client_dashboard_page.dart';
import 'chat/chat_list_page.dart';
import 'settings_page.dart';
import 'calendar_page.dart';
import 'videos_page.dart';
import 'profile_page.dart';
import 'meals_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização do Firebase
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

      // Suporte à localização
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Português (Brasil)
        Locale('en', 'US'), // Inglês (EUA)
      ],
      locale: const Locale('pt', 'BR'), // Idioma padrão: Português (Brasil)

      // Configuração de tema
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

      // Rotas do aplicativo
      initialRoute: '/login', // Define a rota inicial do app
      onGenerateRoute: _generateRoute,
    );
  }

  // Função para gerenciar rotas dinâmicas
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    print('Attempting to generate route: ${settings.name}');

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
     
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfilePage());

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
          return _redirectToLogin();
        }

      case '/meals':
        return MaterialPageRoute(builder: (_) => const MealsPage());

      case '/videos':
        return MaterialPageRoute(builder: (_) => const VideosPage());

      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsPage());

      default:
        // Página 404 personalizada
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Página não encontrada')),
            body: const Center(
              child: Text(
                'A página que você procura não existe.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        );
    }
  }

  // Redireciona para a página de login se o usuário não estiver autenticado
  MaterialPageRoute _redirectToLogin() {
    return MaterialPageRoute(builder: (_) => const LoginSelectionPage());
  }
}
