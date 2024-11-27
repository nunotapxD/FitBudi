import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'youtube_player_dialog.dart';

class WorkoutList extends StatelessWidget {
  final String userId;

  const WorkoutList({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .orderBy('date', descending: true)
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
                subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(workoutData['description']),
                        const Divider(),
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
}