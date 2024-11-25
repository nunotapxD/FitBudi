import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminMealPage extends StatefulWidget {
  final String userId;
  
  const AdminMealPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<AdminMealPage> createState() => _AdminMealPageState();
}

class _AdminMealPageState extends State<AdminMealPage> {
  final _formKey = GlobalKey<FormState>();
  final _mealTypeController = TextEditingController();
  final _mealNameController = TextEditingController();
  final _timeController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();
  final List<String> _ingredients = [];
  final _ingredientController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Lista de tipos de refeição pré-definidos
  final List<String> _mealTypes = [
    'Café da Manhã',
    'Lanche da Manhã',
    'Almoço',
    'Lanche da Tarde',
    'Jantar',
    'Ceia'
  ];

  @override
  void dispose() {
    _mealTypeController.dispose();
    _mealNameController.dispose();
    _timeController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _ingredientController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formattedHour = picked.hour.toString().padLeft(2, '0');
      final formattedMinute = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _timeController.text = '$formattedHour:$formattedMinute';
      });
    }
  }

  void _addIngredient() {
    if (_ingredientController.text.isNotEmpty) {
      setState(() {
        _ingredients.add(_ingredientController.text);
        _ingredientController.clear();
      });
    }
  }

  String? _validateNumber(String? value, String field) {
    if (value == null || value.isEmpty) {
      return 'Campo obrigatório';
    }
    try {
      final number = double.parse(value);
      if (number < 0) {
        return '$field não pode ser negativo';
      }
    } catch (e) {
      return 'Digite um número válido';
    }
    return null;
  }

  Future<void> _saveMeal() async {
    if (_formKey.currentState!.validate()) {
      try {
        final mealData = {
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'mealType': _mealTypeController.text,
          'mealName': _mealNameController.text,
          'time': _timeController.text,
          'calories': int.parse(_caloriesController.text),
          'protein': double.parse(_proteinController.text),
          'carbs': double.parse(_carbsController.text),
          'fats': double.parse(_fatsController.text),
          'ingredients': _ingredients,
          'createdAt': FieldValue.serverTimestamp(),
          'searchKeywords': _generateSearchKeywords(_mealNameController.text),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('meals')
            .add(mealData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Refeição adicionada com sucesso!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao adicionar refeição: $e')),
          );
        }
      }
    }
  }

  List<String> _generateSearchKeywords(String text) {
    // Gera palavras-chave para pesquisa
    final keywords = text.toLowerCase().split(' ');
    final result = <String>[];
    
    for (var keyword in keywords) {
      for (var i = 1; i <= keyword.length; i++) {
        result.add(keyword.substring(0, i));
      }
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Refeição'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveMeal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ),
              // Dropdown para tipo de refeição
              DropdownButtonFormField<String>(
                value: _mealTypeController.text.isEmpty ? null : _mealTypeController.text,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Refeição',
                ),
                items: _mealTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _mealTypeController.text = newValue;
                  }
                },
                validator: (value) => value == null ? 'Selecione um tipo de refeição' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mealNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Refeição',
                  hintText: 'Ex: Ovos mexidos',
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Obrigatório' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: 'Horário',
                  hintText: 'Ex: 08:00',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _selectTime(context),
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Obrigatório' : null,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(
                        labelText: 'Calorias',
                        hintText: 'kcal',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => _validateNumber(value, 'Calorias'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Proteína',
                        hintText: 'g',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => _validateNumber(value, 'Proteína'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Carboidratos',
                        hintText: 'g',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => _validateNumber(value, 'Carboidratos'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _fatsController,
                      decoration: const InputDecoration(
                        labelText: 'Gorduras',
                        hintText: 'g',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => _validateNumber(value, 'Gorduras'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ingredientController,
                      decoration: const InputDecoration(
                        labelText: 'Adicionar Ingrediente',
                        hintText: 'Ex: 2 ovos',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addIngredient,
                  ),
                ],
              ),
              if (_ingredients.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Ingredientes:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._ingredients.map((ingredient) => ListTile(
                  title: Text(ingredient),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle),
                    onPressed: () {
                      setState(() {
                        _ingredients.remove(ingredient);
                      });
                    },
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}