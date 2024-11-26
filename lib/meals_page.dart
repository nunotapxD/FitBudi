// lib/pages/meals_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'AdminMealPage.dart';

class MealPlan {
  final String id;
  final String mealType;
  final String mealName;
  final String time;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final List<String> ingredients;
  final String date;

  MealPlan({
    required this.id,
    required this.mealType,
    required this.mealName,
    required this.time,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.ingredients,
    required this.date,
  });

  factory MealPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealPlan(
      id: doc.id,
      mealType: data['mealType'] ?? '',
      mealName: data['mealName'] ?? '',
      time: data['time'] ?? '',
      calories: (data['calories'] ?? 0).toInt(),
      protein: (data['protein'] ?? 0).toDouble(),
      carbs: data['carbs'] ?? 0.0,
      fats: data['fats'] ?? 0.0,
      ingredients: List<String>.from(data['ingredients'] ?? []),
      date: data['date'] ?? '',
    );
  }
}

class MealsPage extends StatefulWidget {
  final String? userId;
  final bool isAdmin;
  
  const MealsPage({
    super.key, 
    this.userId,
    this.isAdmin = false,
  });

  @override
  State<MealsPage> createState() => _MealsPageState();
}

class _MealsPageState extends State<MealsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  DateTime _selectedDate = DateTime.now();
  bool _notificationsEnabled = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    if (widget.isAdmin && widget.userId != null) {
      _loadUserName();
    }
  }

  Future<void> _loadUserName() async {
    if (widget.userId != null) {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _userName = (userDoc.data() as Map<String, dynamic>)['name'] as String?;
        });
      }
    }
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
      },
    );

    if (mounted) {
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        final bool? result = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        setState(() {
          _notificationsEnabled = result ?? false;
        });
      } else {
        setState(() {
          _notificationsEnabled = true;
        });
      }
    }
  }

  Future<void> _scheduleNotification(MealPlan meal) async {
    if (!_notificationsEnabled) return;

    try {
      final timeparts = meal.time.split(':');
      final hour = int.parse(timeparts[0]);
      final minute = int.parse(timeparts[1]);

      final scheduledTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
        minute,
      );

      if (scheduledTime.isBefore(DateTime.now())) return;

      await _notificationsPlugin.zonedSchedule(
        meal.id.hashCode,
        'Hora da Refeição',
        'Está na hora do seu ${meal.mealType}',
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'meals_channel',
            'Meals Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Erro ao agendar notificação: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2025),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              surface: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final String currentUserId = widget.isAdmin ? widget.userId! : _auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(_userName != null ? 'Plano Alimentar - $_userName' : 'Plano Alimentar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          if (!widget.isAdmin)
            IconButton(
              icon: Icon(
                _notificationsEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: _notificationsEnabled ? Colors.yellow : Colors.grey,
              ),
              onPressed: () async {
                if (_notificationsEnabled) {
                  await _notificationsPlugin.cancelAll();
                  setState(() {
                    _notificationsEnabled = false;
                  });
                } else {
                  await _initializeNotifications();
                }
              },
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('users')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return Center(child: Text('Error: ${userSnapshot.error}'));
          }

          final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          final goals = userData['dailyGoals'] ?? {
            'protein': 180.0,
            'carbs': 220.0,
            'fats': 65.0,
            'calories': 2400.0,
          };

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(currentUserId)
                .collection('meals')
                .where('date', isEqualTo: currentDate)
                .orderBy('time')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final meals = snapshot.data?.docs
                  .map((doc) => MealPlan.fromFirestore(doc))
                  .toList() ??
                  [];

              if (!widget.isAdmin && _notificationsEnabled) {
                for (var meal in meals) {
                  _scheduleNotification(meal);
                }
              }

              final macroTotals = _calculateMacroTotals(meals);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM, yyyy', 'pt_BR')
                        .format(_selectedDate),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildMacrosSummary(macroTotals, goals),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Refeições do Dia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.isAdmin)
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () => _addMeal(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (meals.isEmpty)
                    const Center(
                      child: Text(
                        'Nenhuma refeição planejada para hoje',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...meals.map((meal) => _buildMealCard(meal)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMacrosSummary(Map<String, double> totals, Map<String, dynamic> goals) {
    return Card(
      color: const Color(0xFF2C2C2C),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Progresso Diário',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildProgressBar(
              'Calorias',
              totals['calories'] ?? 0,
              goals['calories']?.toDouble() ?? 2400,
              Colors.orange,
              'kcal',
            ),
            const SizedBox(height: 8),
            _buildProgressBar(
              'Proteínas',
              totals['protein'] ?? 0,
              goals['protein']?.toDouble() ?? 180,
              Colors.red,
              'g',
            ),
            const SizedBox(height: 8),
            _buildProgressBar(
              'Carboidratos',
              totals['carbs'] ?? 0,
              goals['carbs']?.toDouble() ?? 220,
              Colors.green,
              'g',
            ),
            const SizedBox(height: 8),
            _buildProgressBar(
              'Gorduras',
              totals['fats'] ?? 0,
              goals['fats']?.toDouble() ?? 65,
              Colors.blue,
              'g',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
      String label, double current, double goal, Color color, String unit) {
    final percentage = (current / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              '${current.toStringAsFixed(1)}/${goal.toStringAsFixed(1)} $unit',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[800],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildMealCard(MealPlan meal) {
    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          meal.mealType,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          meal.time,
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${meal.calories} kcal',
              style: const TextStyle(color: Colors.orange),
            ),
            if (widget.isAdmin) ...[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _editMeal(meal),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteConfirmDialog(meal),
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.mealName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'P: ${meal.protein}g | C: ${meal.carbs}g | G: ${meal.fats}g',
                  style: const TextStyle(color: Colors.grey),
                ),
                if (meal.ingredients.isNotEmpty) ...[
const Divider(color: Colors.grey),
                  const Text(
                    'Ingredientes:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...meal.ingredients.map((ingredient) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.fiber_manual_record,
                            size: 8, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          ingredient,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateMacroTotals(List<MealPlan> meals) {
    return meals.fold({
      'calories': 0.0,
      'protein': 0.0,
      'carbs': 0.0,
      'fats': 0.0,
    }, (Map<String, double> totals, MealPlan meal) {
      totals['calories'] = (totals['calories'] ?? 0) + meal.calories;
      totals['protein'] = (totals['protein'] ?? 0) + meal.protein;
      totals['carbs'] = (totals['carbs'] ?? 0) + meal.carbs;
      totals['fats'] = (totals['fats'] ?? 0) + meal.fats;
      return totals;
    });
  }

  void _addMeal(BuildContext context) {
    if (!widget.isAdmin || widget.userId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminMealPage(
          userId: widget.userId!,
        ),
      ),
    );
  }

  void _editMeal(MealPlan meal) {
    if (!widget.isAdmin || widget.userId == null) return;

    // TODO: Implementar edição de refeição
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de edição em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showDeleteConfirmDialog(MealPlan meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          'Confirmar Exclusão',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Deseja realmente excluir esta refeição?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                final String userId = widget.isAdmin ? widget.userId! : _auth.currentUser!.uid;
                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('meals')
                    .doc(meal.id)
                    .delete();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refeição excluída com sucesso'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir refeição: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notificationsPlugin.cancelAll();
    super.dispose();
  }
}