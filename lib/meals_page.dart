// lib/pages/meal/meal_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MealPage extends StatefulWidget {
  const MealPage({Key? key}) : super(key: key);

  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime _selectedDate = DateTime.now();
  
  // Calculate total macros for the day
  Map<String, double> _calculateDailyTotals(List<QueryDocumentSnapshot> meals) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFats = 0;

    for (var meal in meals) {
      final data = meal.data() as Map<String, dynamic>;
      totalCalories += (data['calories'] ?? 0).toDouble();
      totalProtein += (data['protein'] ?? 0).toDouble();
      totalCarbs += (data['carbs'] ?? 0).toDouble();
      totalFats += (data['fats'] ?? 0).toDouble();
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fats': totalFats,
    };
  }

  Future<void> _toggleMealEaten(String mealId, bool currentState) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('meals')
          .doc(mealId)
          .update({'eaten': !currentState});
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plano Alimentar'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2025),
                locale: const Locale('pt', 'BR'),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('Usuário não autenticado'))
          : Column(
              children: [
                // Date Navigation
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                          });
                        },
                      ),
                      Column(
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE', 'pt_BR').format(_selectedDate),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate.add(const Duration(days: 1));
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                // Meals List with Daily Summary
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .doc(userId)
                        .collection('meals')
                        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
                          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
                        ))
                        .where('date', isLessThan: Timestamp.fromDate(
                          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + 1),
                        ))
                        .orderBy('date')
                        .orderBy('time')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Erro: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final meals = snapshot.data?.docs ?? [];

                      if (meals.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.no_meals_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhuma refeição programada para\n${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final dailyTotals = _calculateDailyTotals(meals);

                      return Column(
                        children: [
                          // Daily Summary Card
                          Card(
                            margin: const EdgeInsets.all(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total do Dia',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildMacroSummary(
                                        'Calorias',
                                        '${dailyTotals['calories']?.toInt() ?? 0}',
                                        'kcal',
                                        Colors.orange,
                                      ),
                                      _buildMacroSummary(
                                        'Proteínas',
                                        '${dailyTotals['protein']?.toInt() ?? 0}',
                                        'g',
                                        Colors.red,
                                      ),
                                      _buildMacroSummary(
                                        'Carboidratos',
                                        '${dailyTotals['carbs']?.toInt() ?? 0}',
                                        'g',
                                        Colors.green,
                                      ),
                                      _buildMacroSummary(
                                        'Gorduras',
                                        '${dailyTotals['fats']?.toInt() ?? 0}',
                                        'g',
                                        Colors.blue,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Meals List
                          Expanded(
                            child: ListView.builder(
                              itemCount: meals.length,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemBuilder: (context, index) {
                                final meal = meals[index].data() as Map<String, dynamic>;
                                final eaten = meal['eaten'] as bool;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent,
                                    ),
                                    child: ExpansionTile(
                                      title: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              meal['time'],
                                              style: TextStyle(
                                                color: theme.primaryColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              meal['mealName'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        meal['mealType'],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          eaten ? Icons.check_circle : Icons.check_circle_outline,
                                          color: eaten ? Colors.green : Colors.grey,
                                          size: 28,
                                        ),
                                        onPressed: () => _toggleMealEaten(meals[index].id, eaten),
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Divider(),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  _buildNutrientChip(
                                                    'Calorias',
                                                    '${meal['calories']} kcal',
                                                    Colors.orange,
                                                  ),
                                                  _buildNutrientChip(
                                                    'Proteínas',
                                                    '${meal['protein']}g',
                                                    Colors.red,
                                                  ),
                                                  _buildNutrientChip(
                                                    'Carboidratos',
                                                    '${meal['carbs']}g',
                                                    Colors.green,
                                                  ),
                                                  _buildNutrientChip(
                                                    'Gorduras',
                                                    '${meal['fats']}g',
                                                    Colors.blue,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMacroSummary(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: unit,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}