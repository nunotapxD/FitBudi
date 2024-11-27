import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String name;
  final String description;
  final String? youtubeUrl;
  final int sets;
  final int reps;
  final double weight;

  Exercise({
    required this.name,
    required this.description,
    this.youtubeUrl,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'youtubeUrl': youtubeUrl,
      'sets': sets,
      'reps': reps,
      'weight': weight,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      youtubeUrl: map['youtubeUrl'],
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? 0,
      weight: (map['weight'] ?? 0).toDouble(),
    );
  }
}