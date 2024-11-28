import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'AdminMealPage.dart';
import 'user_calendar_widget.dart';
import 'widgets/youtube_player_dialog.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? userName;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> deletedUsers = [];
  String? selectedUserId;
  String selectedUserName = '';
  String currentSection = '';

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

  Future<void> _deleteUser(String userId) async {
    if (_auth.currentUser?.uid != userId) {
      await _firestore.collection('users').doc(userId).update({'deleted': 1});
      await _fetchUsers();
      setState(() {
        selectedUserId = null;
        selectedUserName = '';
        currentSection = '';
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao fazer logout')),
      );
    }
  }

  void _showDeleteConfirmation(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o usuário $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(userId);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          selectedUserName.isEmpty ? 'Admin' : selectedUserName,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (selectedUserId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => _showDeleteConfirmation(selectedUserId!, selectedUserName),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: selectedUserId == null ? _buildUserList() : _buildUserDashboard(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                (user['name'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user['name'] ?? 'Sem nome'),
            subtitle: Text(user['email'] ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() {
                selectedUserId = user['uid'];
                selectedUserName = user['name'] ?? 'Sem nome';
                currentSection = '';
              });
            },
          ),
        );
      },
    );
  }

Widget _buildUserDashboard() {
    if (currentSection.isEmpty) {
      return GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildNavigationCard(
            title: 'Treinos',
            icon: Icons.fitness_center,
            color: Colors.purple,
            onTap: () => setState(() => currentSection = 'workouts'),
          ),
          _buildNavigationCard(
            title: 'Refeições',
            icon: Icons.restaurant_menu,
            color: Colors.orange,
            onTap: () => setState(() => currentSection = 'meals'),
          ),
          _buildNavigationCard(
            title: 'Peso',
            icon: Icons.monitor_weight,
            color: Colors.blue,
            onTap: () => setState(() => currentSection = 'weight'),
          ),
          _buildNavigationCard(
            title: 'Voltar',
            icon: Icons.arrow_back,
            color: Colors.grey,
            onTap: () => setState(() {
              selectedUserId = null;
              selectedUserName = '';
              currentSection = '';
            }),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: TextButton.icon(
              onPressed: () => setState(() => currentSection = ''),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar para o menu'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Expanded(
            child: _buildSelectedSection(),
          ),
        ],
      );
    }
  }

  Widget _buildNavigationCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ActionChip(
      avatar: Icon(
        icon,
        color: isSelected ? Colors.white : Theme.of(context).primaryColor,
        size: 20,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).primaryColor,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.white,
      onPressed: onSelected,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildSelectedSection() {
    switch (currentSection) {
      case 'workouts':
        return _buildWorkoutList();
      case 'meals':
        return _buildMealsList();
      case 'weight':
        return _buildWeightHistory();
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Selecione uma opção acima',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildWorkoutList() {
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
          padding: const EdgeInsets.all(8),
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workoutData = workouts[index].data() as Map<String, dynamic>;
            final exercises = List<Map<String, dynamic>>.from(workoutData['exercises'] ?? []);
            final date = (workoutData['date'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(workoutData['name']),
                subtitle: Text('${DateFormat('dd/MM/yyyy').format(date)} - ${exercises.length} exercícios'),
                children: [
                  if (workoutData['description']?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        workoutData['description'],
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: exercises.length,
                    itemBuilder: (context, i) {
                      final exercise = exercises[i];
                      return ListTile(
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
                      );
                    },
                  ),
                  ButtonBar(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.delete, size: 20),
                        label: const Text('Excluir'),
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
            );
          },
        );
      },
    );
  }

  Widget _buildMealsList() {
    return StreamBuilder<QuerySnapshot>(
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
          return const Center(child: Text('Nenhuma refeição cadastrada'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: meals.length,
          itemBuilder: (context, index) {
            final meal = meals[index].data() as Map<String, dynamic>;
            final date = (meal['date'] as Timestamp).toDate();
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
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
    );
  }

  Widget _buildWeightHistory() {
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

        final records = snapshot.data?.docs ?? [];

        if (records.isEmpty) {
          return const Center(child: Text('Nenhum registro de peso encontrado'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index].data() as Map<String, dynamic>;
            final date = (record['date'] as Timestamp).toDate();
            final weight = record['weight'] as double;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
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
                        .doc(records[index].id)
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

  FloatingActionButton? _buildFloatingActionButton() {
    if (selectedUserId == null) return null;

    VoidCallback? onPressed;
    IconData icon = Icons.add;
    String tooltip = '';

    switch (currentSection) {
      case 'workouts':
        onPressed = () => _showAddWorkoutDialog(selectedUserId!);
        tooltip = 'Adicionar Treino';
        break;
      case 'meals':
        onPressed = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminMealPage(userId: selectedUserId!),
            ),
          );
        };
        tooltip = 'Adicionar Refeição';
        break;
      case 'weight':
        onPressed = () => _showAddWeightDialog(selectedUserId!);
        tooltip = 'Registrar Peso';
        break;
    }

    return onPressed != null
        ? FloatingActionButton(
            onPressed: onPressed,
            tooltip: tooltip,
            backgroundColor: Theme.of(context).primaryColor,
            child: Icon(icon),
          )
        : null;
  }

  void _showAddWorkoutDialog(String userId) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final dateController = TextEditingController();
    List<Map<String, dynamic>> exercises = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Novo Treino'),
              content: SingleChildScrollView(
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
                    if (exercises.isNotEmpty) ...[
                      const Text('Exercícios:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...exercises.asMap().entries.map((entry) {
                        final exercise = entry.value;
                        return Card(
                          child: ListTile(
                            title: Text(exercise['name']),
                            subtitle: Text(
                              '${exercise['sets']}x${exercise['reps']} - ${exercise['weight']}kg'
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  exercises.removeAt(entry.key);
                                });
                              },
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddExerciseDialog(context, (exercise) {
                        setState(() {
                          exercises.add(exercise);
                        });
                      }),
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar Exercício'),
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

  void _showAddExerciseDialog(BuildContext context, Function(Map<String, dynamic>) onAdd) {
    final exerciseNameController = TextEditingController();
    final exerciseDescController = TextEditingController();
    final youtubeUrlController = TextEditingController();
    final setsController = TextEditingController();
    final repsController = TextEditingController();
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Exercício'),
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
                maxLines: 2,
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
                onAdd({
                  'name': exerciseNameController.text,
                  'description': exerciseDescController.text,
                  'youtubeUrl': youtubeUrlController.text.isEmpty ? null : youtubeUrlController.text,
                  'sets': int.tryParse(setsController.text) ?? 0,
                  'reps': int.tryParse(repsController.text) ?? 0,
                  'weight': double.tryParse(weightController.text) ?? 0.0,
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddWeightDialog(String userId) async {
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

                  await _firestore.collection('users').doc(userId).collection('weight_history').add({
                    'weight': weight,
                    'date': Timestamp.fromDate(date),
                    'timestamp': Timestamp.fromDate(date),
                  });

                  await _firestore.collection('users').doc(userId).update({
                    'weight': weight,
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Peso registrado com sucesso!')),
                  );
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
}