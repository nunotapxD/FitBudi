import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

class ClientDashboardPage extends StatefulWidget {
  const ClientDashboardPage({super.key});

  @override
  State<ClientDashboardPage> createState() => _ClientDashboardPageState();
}

class _ClientDashboardPageState extends State<ClientDashboardPage> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao fazer logout')),
      );
    }
  }

 /* String _getFormattedDate() {
    final now = DateTime.now();
    return DateFormat.yMMMMEEEEd('pt_BR').format(now);
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitBudi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            
          /*  // Data atual
            Column(
              children: [
                Text(
             //     _getFormattedDate(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bem-vindo de volta!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),*/
            
           // const SizedBox(height: 32),
            
            // Grid de funcionalidades
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildDashboardItem(
                    context,
                    'Agenda',
                    Icons.calendar_today,
                    Colors.blue,
                    () => Navigator.pushNamed(context, '/calendar'),
                  ),
                  _buildDashboardItem(
                    context,
                    'Refeições',
                    Icons.restaurant,
                    Colors.orange,
                    () => Navigator.pushNamed(context, '/meals'),
                  ),
                  _buildDashboardItem(
                    context,
                    'Vídeos',
                    Icons.play_circle,
                    Colors.red,
                    () => Navigator.pushNamed(context, '/videos'),
                  ),
                  _buildDashboardItem(
                    context,
                    'Chat',
                    Icons.chat,
                    Colors.green,
                    () {
                      Navigator.of(context).pushNamed('/chat');
                    },
                  ),
                  _buildDashboardItem(
                    context,
                    'Perfil',
                    Icons.person_off_outlined,
                    Colors.yellow,
                    () {
                      Navigator.of(context).pushNamed('/profile');
                    },
                  ),
                  _buildDashboardItem(
                    context,
                    'Settings',
                    Icons.settings,
                    const Color.fromARGB(255, 112, 112, 112),
                    () {
                      Navigator.of(context).pushNamed('/settings');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

     /* bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavButton(
                context,
                Icons.home,
                'Home',
                () {}, // Já estamos na home
                isSelected: true,
              ),
              _buildNavButton(
                context,
                Icons.fitness_center,
                'Treinos',
                () => Navigator.pushNamed(context, '/workouts'),
              ),
              _buildNavButton(
                context,
                Icons.person,
                'Perfil',
                () => Navigator.pushNamed(context, '/profile'),
              ),
              _buildNavButton(
                context,
                Icons.settings,
                'Config',
                () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
        ),
      ),*/
    );
  }

  Widget _buildDashboardItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);
    final color = isSelected ? theme.primaryColor : Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}