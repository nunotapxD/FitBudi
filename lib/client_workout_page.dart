import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'widgets/youtube_player_dialog.dart';

class ClientWorkoutPage extends StatefulWidget {
  const ClientWorkoutPage({Key? key}) : super(key: key);

  @override
  State<ClientWorkoutPage> createState() => _ClientWorkoutPageState();
}

class _ClientWorkoutPageState extends State<ClientWorkoutPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Treinos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2025),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                  .doc(_auth.currentUser?.uid)
                  .collection('workouts')
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)))
                  .where('date', isLessThan: Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + 1)))
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                  /*      Image.asset(
                          '/lib/assets/no_workout.png', // Add this image to your assets
                          height: 120,
                          color: Colors.grey[400],
                        ),*/
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum treino para ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
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
                  itemCount: workouts.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final workoutData = workouts[index].data() as Map<String, dynamic>;
                    final exercises = List<Map<String, dynamic>>.from(workoutData['exercises'] ?? []);

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          title: Text(
                            workoutData['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            '${exercises.length} exercício${exercises.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          children: [
                            if (workoutData['description']?.isNotEmpty ?? false)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(
                                  workoutData['description'],
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            const Divider(),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: exercises.length,
                              itemBuilder: (context, index) {
                                final exercise = exercises[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(exercise['name']),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${exercise['sets']}x${exercise['reps']} - ${exercise['weight']}kg',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (exercise['description']?.isNotEmpty ?? false)
                                        Text(exercise['description']),
                                    ],
                                  ),
                                  trailing: exercise['youtubeUrl'] != null
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.play_circle_outline,
                                            color: Colors.red,
                                          ),
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
                                  isThreeLine: exercise['description']?.isNotEmpty ?? false,
                                );
                              },
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
    );
  }
}