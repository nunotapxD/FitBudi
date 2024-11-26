import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'AdminMealPage.dart';
import 'calendar_page.dart';

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

  void _showAddMealDialog(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminMealPage(userId: userId),
      ),
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
                  if (userName != null) // Só mostra se o userName foi carregado
                    ListTile(
                      title: Text(userName!),
                      subtitle: const Text('Admin'),
                      tileColor: Colors.blue[100],
                      onTap: () {
                        setState(() {
                          selectedUserId = _auth.currentUser!.uid;
                          showDeletedUsers = false;
                          showMeals = false;
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
                              leading: const Icon(Icons.restaurant_menu),
                              title: const Text('Gerenciar Refeições'),
                              onTap: () {
                                setState(() {
                                  selectedUserId = user['uid'];
                                  showDeletedUsers = false;
                                  showMeals = true;
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
              child: showDeletedUsers
                  ? _buildDeletedUsersList()
                  : showMeals
                      ? _buildMealManagement()
                      : selectedUserId == null
                          ? const Center(child: Text('Selecione um usuário'))
                          : UserCalendarWidget(userId: selectedUserId!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedUsersList() {
    return ListView.builder(
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
    );
  }

  Widget _buildMealManagement() {
    if (selectedUserId == null) {
      return const Center(child: Text('Selecione um usuário'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: () => _showAddMealDialog(selectedUserId!),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(selectedUserId)
                .collection('meals')
                .orderBy('date')
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
                  return Card(
                    child: ListTile(
                      title: Text(meal['mealName'] ?? ''),
                      subtitle: Text(
                        '${meal['mealType']} - ${meal['time']}\n'
                        'Calorias: ${meal['calories']} kcal | '
                        'P: ${meal['protein']}g | '
                        'C: ${meal['carbs']}g | '
                        'G: ${meal['fats']}g',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // TODO: Implementar edição
                            },
                          ),
                          IconButton(
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
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class UserCalendarWidget extends StatelessWidget {
  final String userId;

  const UserCalendarWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return CalendarPage(
      userId: userId,
      isAdmin: true,
    );
  }
}