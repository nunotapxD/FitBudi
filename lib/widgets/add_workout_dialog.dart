// widgets/add_workout_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_exercise_dialog.dart';

class AddWorkoutDialog extends StatefulWidget {
  final String userId;

  const AddWorkoutDialog({Key? key, required this.userId}) : super(key: key);

  @override
  State<AddWorkoutDialog> createState() => _AddWorkoutDialogState();
}

class _AddWorkoutDialogState extends State<AddWorkoutDialog> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final dateController = TextEditingController();
  final List<Map<String, dynamic>> exercises = [];
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Adicionar Treino',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Treino',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Por favor, insira um nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
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
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Por favor, selecione uma data';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Exercícios:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (exercises.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return Card(
                          child: ListTile(
                            title: Text(exercise['name']),
                            subtitle: Text(
                              '${exercise['sets']}x${exercise['reps']} - ${exercise['weight']}kg',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  exercises.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Exercício'),
                          onPressed: () async {
                            final result = await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (context) => const AddExerciseDialog(),
                            );
                            if (result != null) {
                              setState(() {
                                exercises.add(result);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate() && exercises.isNotEmpty) {
                            final date = DateFormat('dd/MM/yyyy').parse(dateController.text);
                            
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.userId)
                                .collection('workouts')
                                .add({
                              'name': nameController.text,
                              'description': descriptionController.text,
                              'date': Timestamp.fromDate(date),
                              'exercises': exercises,
                              'timestamp': Timestamp.fromDate(DateTime.now()),
                            });
                            
                            Navigator.pop(context);
                          } else if (exercises.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Adicione pelo menos um exercício'),
                              ),
                            );
                          }
                        },
                        child: const Text('Salvar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}