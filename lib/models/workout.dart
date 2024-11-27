import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise.dart';

class Workout {
  final String name;
  final String description;
  final DateTime date;
  final List<Exercise> exercises;

  Workout({
    required this.name,
    required this.description,
    required this.date,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'date': Timestamp.fromDate(date),
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      exercises: List<Exercise>.from(
        (map['exercises'] as List).map((e) => Exercise.fromMap(e)),
      ),
    );
  }
}