// lib/pages/admin/admin_meal_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminMealPage extends StatefulWidget {
  final String userId;
  const AdminMealPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<AdminMealPage> createState() => _AdminMealPageState();
}

class _AdminMealPageState extends State<AdminMealPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();

  Future<void> _addMeal() async {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatsController = TextEditingController();
    final timeController = TextEditingController();
    final dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_selectedDate),
    );
    String selectedMealType = 'Café da Manhã';

    final mealTypes = [
      'Café da Manhã',
      'Lanche da Manhã',
      'Almoço',
      'Lanche da Tarde',
      'Jantar',
      'Ceia',
      'Pré-Treino',
      'Pós-Treino',
    ];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Refeição'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Refeição',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant_menu),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMealType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Refeição',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: mealTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedMealType = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Data',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2025),
                          locale: const Locale('pt', 'BR'),
                        );
                        if (date != null) {
                          dateController.text = DateFormat('dd/MM/yyyy').format(date);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: timeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Horário',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calorias (kcal)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_fire_department),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: proteinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Proteínas (g)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.egg),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: carbsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Carboidratos (g)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.rice_bowl),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Gorduras (g)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.water_drop),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  timeController.text.isEmpty ||
                  dateController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha todos os campos obrigatórios'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final date = DateFormat('dd/MM/yyyy').parse(dateController.text);

              await _firestore
                  .collection('users')
                  .doc(widget.userId)
                  .collection('meals')
                  .add({
                'mealName': nameController.text,
                'mealType': selectedMealType,
                'date': Timestamp.fromDate(date),
                'time': timeController.text,
                'calories': int.tryParse(caloriesController.text) ?? 0,
                'protein': double.tryParse(proteinController.text) ?? 0,
                'carbs': double.tryParse(carbsController.text) ?? 0,
                'fats': double.tryParse(fatsController.text) ?? 0,
                'eaten': false,
                'timestamp': Timestamp.now(),
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refeição adicionada com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyMealToNextDays(Map<String, dynamic> meal, String mealId) async {
    final daysController = TextEditingController(text: '1');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copiar Refeição'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Copiar esta refeição para os próximos dias:'),
            const SizedBox(height: 16),
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número de dias',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final days = int.tryParse(daysController.text) ?? 0;
              if (days > 0) {
                final originalDate = (meal['date'] as Timestamp).toDate();
                
                for (int i = 1; i <= days; i++) {
                  final newDate = originalDate.add(Duration(days: i));
                  await _firestore
                      .collection('users')
                      .doc(widget.userId)
                      .collection('meals')
                      .add({
                    ...meal,
                    'date': Timestamp.fromDate(newDate),
                    'eaten': false,
                    'timestamp': Timestamp.now(),
                  });
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Refeição copiada para $days dias'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Refeições'),
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(widget.userId)
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

                return ListView.builder(
                  itemCount: meals.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final mealDoc = meals[index];
                    final meal = mealDoc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                meal['time'],
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                meal['mealName'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meal['mealType']),
                            const SizedBox(height: 4),
                            Text(
                              'Calorias: ${meal['calories']} kcal | '
'P: ${meal['protein']}g | '
                              'C: ${meal['carbs']}g | '
                              'G: ${meal['fats']}g',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            switch (value) {
                              case 'edit':
                                // Implementar edição
                                break;
                              case 'copy':
                                await _copyMealToNextDays(meal, mealDoc.id);
                                break;
                              case 'delete':
                                await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirmar Exclusão'),
                                    content: const Text(
                                      'Tem certeza que deseja excluir esta refeição?'
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      FilledButton(
                                        onPressed: () async {
                                          await _firestore
                                              .collection('users')
                                              .doc(widget.userId)
                                              .collection('meals')
                                              .doc(mealDoc.id)
                                              .delete();
                                          Navigator.pop(context);
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'copy',
                              child: Row(
                                children: [
                                  Icon(Icons.copy),
                                  SizedBox(width: 8),
                                  Text('Copiar para próximos dias'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Excluir', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMeal,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditMealDialog(String mealId, Map<String, dynamic> currentMeal) async {
    final nameController = TextEditingController(text: currentMeal['mealName']);
    final caloriesController = TextEditingController(text: currentMeal['calories'].toString());
    final proteinController = TextEditingController(text: currentMeal['protein'].toString());
    final carbsController = TextEditingController(text: currentMeal['carbs'].toString());
    final fatsController = TextEditingController(text: currentMeal['fats'].toString());
    final timeController = TextEditingController(text: currentMeal['time']);
    final dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format((currentMeal['date'] as Timestamp).toDate()),
    );
    String selectedMealType = currentMeal['mealType'];

    final mealTypes = [
      'Café da Manhã',
      'Lanche da Manhã',
      'Almoço',
      'Lanche da Tarde',
      'Jantar',
      'Ceia',
      'Pré-Treino',
      'Pós-Treino',
    ];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Editar Refeição'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Refeição',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant_menu),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMealType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Refeição',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: mealTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedMealType = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Data',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: (currentMeal['date'] as Timestamp).toDate(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2025),
                          locale: const Locale('pt', 'BR'),
                        );
                        if (date != null) {
                          dateController.text = DateFormat('dd/MM/yyyy').format(date);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: timeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Horário',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: int.parse(timeController.text.split(':')[0]),
                            minute: int.parse(timeController.text.split(':')[1]),
                          ),
                        );
                        if (time != null) {
                          timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calorias (kcal)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_fire_department),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: proteinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Proteínas (g)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.egg),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: carbsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Carboidratos (g)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.rice_bowl),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Gorduras (g)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.water_drop),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  timeController.text.isEmpty ||
                  dateController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha todos os campos obrigatórios'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final date = DateFormat('dd/MM/yyyy').parse(dateController.text);

              await _firestore
                  .collection('users')
                  .doc(widget.userId)
                  .collection('meals')
                  .doc(mealId)
                  .update({
                'mealName': nameController.text,
                'mealType': selectedMealType,
                'date': Timestamp.fromDate(date),
                'time': timeController.text,
                'calories': int.tryParse(caloriesController.text) ?? 0,
                'protein': double.tryParse(proteinController.text) ?? 0,
                'carbs': double.tryParse(carbsController.text) ?? 0,
                'fats': double.tryParse(fatsController.text) ?? 0,
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refeição atualizada com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}