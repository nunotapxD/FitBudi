import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'AdminMealPage.dart';
import 'user_calendar_widget.dart';
import 'widgets/workout_list.dart';
import 'widgets/add_workout_dialog.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'widgets/youtube_player_dialog.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userName;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> deletedUsers = [];
  String? selectedUserId;
  bool showDeletedUsers = false;
  bool showMeals = false;
  bool showWeightHistory = false;
  bool showWorkouts = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUsers();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          userName = (userDoc.data() as Map<String, dynamic>)['name'] as String?;
          selectedUserId = user.uid;
        });
      }
    }
  }

  Future<void> _fetchUsers() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('deleted', isNotEqualTo: 1)
        .get();
        
    if (mounted) {
      setState(() {
        users = querySnapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'uid': doc.id,
                })
            .where((user) => user['uid'] != _auth.currentUser?.uid)
            .toList();
      });
    }
  }

  Future<void> _fetchDeletedUsers() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('deleted', isEqualTo: 1)
        .get();
        
    if (mounted) {
      setState(() {
        deletedUsers = querySnapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'uid': doc.id,
                })
            .toList();
        showDeletedUsers = true;
      });
    }
  }

  Future<void> _deleteUser(String userId) async {
    if (_auth.currentUser?.uid != userId) {
      await _firestore.collection('users').doc(userId).update({'deleted': 1});
      await _fetchUsers();
    }
  }

  Future<void> _restoreUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({'deleted': 0});
    await _fetchDeletedUsers();
    await _fetchUsers();
    if (mounted) {
      setState(() {
        showDeletedUsers = false;
      });
    }
  }

void _showAddWorkoutDialog(String userId) {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final dateController = TextEditingController();
  List<Map<String, dynamic>> exercises = [];

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Adicionar Treino'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Treino',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Data',
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2025),
                        );
                        if (date != null) {
                          dateController.text = DateFormat('dd/MM/yyyy').format(date);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Exercícios:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return ListTile(
                          title: Text(exercise['name']),
                          subtitle: Text(
                            '${exercise['sets']}x${exercise['reps']} - ${exercise['weight']}kg'
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                exercises.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final exerciseNameController = TextEditingController();
                        final exerciseDescController = TextEditingController();
                        final youtubeUrlController = TextEditingController();
                        final setsController = TextEditingController();
                        final repsController = TextEditingController();
                        final weightController = TextEditingController();

                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Adicionar Exercício'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: exerciseNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nome do Exercício',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: exerciseDescController,
                                    decoration: const InputDecoration(
                                      labelText: 'Descrição',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: youtubeUrlController,
                                    decoration: const InputDecoration(
                                      labelText: 'URL do YouTube (opcional)',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: setsController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Séries',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: repsController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Repetições',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: weightController,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Peso (kg)',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (exerciseNameController.text.isNotEmpty) {
                                    setState(() {
                                      exercises.add({
                                        'name': exerciseNameController.text,
                                        'description': exerciseDescController.text,
                                        'youtubeUrl': youtubeUrlController.text.isEmpty ? null : youtubeUrlController.text,
                                        'sets': int.tryParse(setsController.text) ?? 0,
                                        'reps': int.tryParse(repsController.text) ?? 0,
                                        'weight': double.tryParse(weightController.text) ?? 0.0,
                                      });
                                    });
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text('Adicionar'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Exercício'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      dateController.text.isNotEmpty &&
                      exercises.isNotEmpty) {
                    final date = DateFormat('dd/MM/yyyy').parse(dateController.text);
                    
                    await _firestore
                        .collection('users')
                        .doc(userId)
                        .collection('workouts')
                        .add({
                      'name': nameController.text,
                      'description': descriptionController.text,
                      'date': Timestamp.fromDate(date),
                      'exercises': exercises,
                      'timestamp': Timestamp.fromDate(DateTime.now()),
                    });
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Treino adicionado com sucesso!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preencha todos os campos obrigatórios'),
                      ),
                    );
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      );
    },
  );
}

  Widget _buildWorkoutList() {
    if (selectedUserId == null) {
      return const Center(child: Text('Selecione um usuário'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(selectedUserId)
          .collection('workouts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final workouts = snapshot.data?.docs ?? [];

        if (workouts.isEmpty) {
          return const Center(child: Text('Nenhum treino cadastrado'));
        }

        return ListView.builder(
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workoutData = workouts[index].data() as Map<String, dynamic>;
            final exercises = List<Map<String, dynamic>>.from(workoutData['exercises'] ?? []);
            final date = (workoutData['date'] as Timestamp).toDate();

            return Card(
              child: ExpansionTile(
                title: Text(workoutData['name']),
                subtitle: Text('${DateFormat('dd/MM/yyyy').format(date)} - ${exercises.length} exercícios'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (workoutData['description']?.isNotEmpty ?? false) ...[
                          Text(
                            workoutData['description'],
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                          const Divider(),
                        ],
                        ...exercises.map((exercise) => ListTile(
                          title: Text(exercise['name']),
                          subtitle: Text(
                            '${exercise['sets']}x${exercise['reps']} - ${exercise['weight']}kg\n'
                            '${exercise['description']}',
                          ),
                          trailing: exercise['youtubeUrl'] != null
                              ? IconButton(
                                  icon: const Icon(Icons.play_circle),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => YoutubePlayerDialog(
                                        youtubeUrl: exercise['youtubeUrl'],
                                      ),
                                    );
                                  },
                                )
                              : null,
                        )),
                        ButtonBar(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.delete),
                              label: const Text('Excluir Treino'),
                              onPressed: () async {
                                await _firestore
                                    .collection('users')
                                    .doc(selectedUserId)
                                    .collection('workouts')
                                    .doc(workouts[index].id)
                                    .delete();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

void _showAddWeightDialog(String userId) {
    final weightController = TextEditingController();
    final dateController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Peso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                hintText: 'Ex: 70.5',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Data',
                hintText: 'Selecione a data',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  dateController.text = DateFormat('dd/MM/yyyy').format(date);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (weightController.text.isNotEmpty && dateController.text.isNotEmpty) {
                try {
                  final weight = double.parse(weightController.text);
                  final date = DateFormat('dd/MM/yyyy').parse(dateController.text);
                  
                  await _firestore
                      .collection('users')
                      .doc(userId)
                      .collection('weight_history')
                      .add({
                    'weight': weight,
                    'date': date,
                    'timestamp': Timestamp.fromDate(date),
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Peso registrado com sucesso!')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao registrar peso. Verifique os dados.')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preencha todos os campos')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightHistory() {
    if (selectedUserId == null) {
      return const Center(child: Text('Selecione um usuário'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(selectedUserId)
          .collection('weight_history')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final weightRecords = snapshot.data?.docs ?? [];

        if (weightRecords.isEmpty) {
          return const Center(
            child: Text('Nenhum registro de peso encontrado'),
          );
        }

        return ListView.builder(
          itemCount: weightRecords.length,
          itemBuilder: (context, index) {
            final record = weightRecords[index].data() as Map<String, dynamic>;
            final date = (record['date'] as Timestamp).toDate();
            final weight = record['weight'] as double;

            return Card(
              child: ListTile(
                title: Text('${weight.toStringAsFixed(1)} kg'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await _firestore
                        .collection('users')
                        .doc(selectedUserId)
                        .collection('weight_history')
                        .doc(weightRecords[index].id)
                        .delete();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Row(
        children: [
          // Sidebar Esquerda
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[200],
              child: Column(
                children: [
                  if (userName != null)
                    ListTile(
                      title: Text(userName!),
                      subtitle: const Text('Admin'),
                      tileColor: Colors.blue[100],
                      onTap: () {
                        setState(() {
                          selectedUserId = _auth.currentUser!.uid;
                          showDeletedUsers = false;
                          showMeals = false;
                          showWeightHistory = false;
                          showWorkouts = false;
                        });
                      },
                    ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ExpansionTile(
                          title: Text(user['name'] ?? 'Sem nome'),
subtitle: Text(user['email'] ?? 'Sem email'),
                          children: [
                            ListTile(
                              leading: const Icon(Icons.fitness_center),
                              title: const Text('Gerenciar Treinos'),
                              onTap: () {
                                setState(() {
                                  selectedUserId = user['uid'];
                                  showDeletedUsers = false;
                                  showMeals = false;
                                  showWeightHistory = false;
                                  showWorkouts = true;
                                });
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.restaurant_menu),
                              title: const Text('Gerenciar Refeições'),
                              onTap: () {
                                setState(() {
                                  selectedUserId = user['uid'];
                                  showDeletedUsers = false;
                                  showMeals = true;
                                  showWeightHistory = false;
                                  showWorkouts = false;
                                });
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.monitor_weight),
                              title: const Text('Histórico de Peso'),
                              onTap: () {
                                setState(() {
                                  selectedUserId = user['uid'];
                                  showDeletedUsers = false;
                                  showMeals = false;
                                  showWeightHistory = true;
                                  showWorkouts = false;
                                });
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: const Text('Ver Calendário'),
                              onTap: () {
                                setState(() {
                                  selectedUserId = user['uid'];
                                  showDeletedUsers = false;
                                  showMeals = false;
                                  showWeightHistory = false;
                                  showWorkouts = false;
                                });
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete),
                              title: const Text('Deletar Usuário'),
                              onTap: () => _deleteUser(user['uid']),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      onPressed: _fetchDeletedUsers,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Usuários Deletados'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Seção Direita
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showWorkouts && selectedUserId != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Gerenciamento de Treinos',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Treino'),
                          onPressed: () => _showAddWorkoutDialog(selectedUserId!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: _buildWorkoutList()),
                  ] else if (showWeightHistory) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Histórico de Peso',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Registrar Peso'),
                          onPressed: () => _showAddWeightDialog(selectedUserId!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: _buildWeightHistory()),
                  ] else if (showDeletedUsers) ...[
                    const Text(
                      'Usuários Deletados',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: deletedUsers.length,
                        itemBuilder: (context, index) {
                          final user = deletedUsers[index];
                          return Card(
                            child: ListTile(
                              title: Text(user['name'] ?? 'Sem nome'),
                              subtitle: Text(user['email'] ?? 'Sem email'),
                              trailing: IconButton(
                                icon: const Icon(Icons.restore),
                                onPressed: () => _restoreUser(user['uid']),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else if (showMeals && selectedUserId != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Gerenciamento de Refeições',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Refeição'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminMealPage(userId: selectedUserId!),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('users')
                            .doc(selectedUserId)
                            .collection('meals')
                            .orderBy('timestamp', descending: true)
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
                            return const Center(
                              child: Text('Nenhuma refeição cadastrada'),
                            );
                          }

                          return ListView.builder(
                            itemCount: meals.length,
                            itemBuilder: (context, index) {
                              final meal = meals[index].data() as Map<String, dynamic>;
                              final date = (meal['date'] as Timestamp).toDate();
                              return Card(
                                child: ListTile(
                                  title: Text(meal['mealName'] ?? ''),
                                  subtitle: Text(
                                    '${meal['mealType']} - ${DateFormat('dd/MM/yyyy').format(date)} ${meal['time']}\n'
                                    'Calorias: ${meal['calories']} kcal | '
                                    'P: ${meal['protein']}g | '
                                    'C: ${meal['carbs']}g | '
                                    'G: ${meal['fats']}g',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      await _firestore
                                          .collection('users')
                                          .doc(selectedUserId)
                                          .collection('meals')
                                          .doc(meals[index].id)
                                          .delete();
                                    },
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ] else if (selectedUserId != null) ...[
                    Expanded(
                      child: UserCalendarWidget(
                        userId: selectedUserId!,
                        isAdmin: true,
                      ),
                    ),
                  ] else ...[
                    const Expanded(
                      child: Center(
                        child: Text('Selecione um usuário'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}