import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String _name = '';
  String _email = '';
  double? _weight;
  double? _height;
  String? _gender; // 'M' ou 'F'
  DateTime? _birthDate;
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _user = _auth.currentUser;
      if (_user != null) {
        _name = _user!.displayName ?? 'Usuário';
        _email = _user!.email ?? 'Sem e-mail';

        // Obter informações do Firestore
        final doc = await _firestore.collection('users').doc(_user!.uid).get();
        if (doc.exists) {
          final data = doc.data();
          _weight = data?['weight']?.toDouble();
          _height = data?['height']?.toDouble();
          _gender = data?['gender'];
          _birthDate = data?['birthDate'] != null
              ? (data!['birthDate'] as Timestamp).toDate()
              : null;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar informações: $e')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveUserInfo() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final weight = double.parse(_weightController.text);
        final height = double.parse(_heightController.text);
        final gender = _gender!;
        final birthDate = DateFormat('dd/MM/yyyy').parse(_birthDateController.text);

        await _firestore.collection('users').doc(_user!.uid).set({
          'weight': weight,
          'height': height,
          'gender': gender,
          'birthDate': birthDate,
        }, SetOptions(merge: true));

        setState(() {
          _weight = weight;
          _height = height;
          _gender = gender;
          _birthDate = birthDate;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados salvos com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar os dados: $e')),
        );
      }
    }
  }

  String? _calculateAge() {
    if (_birthDate == null) return null;
    final today = DateTime.now();
    int age = today.year - _birthDate!.year;
    if (today.month < _birthDate!.month ||
        (today.month == _birthDate!.month && today.day < _birthDate!.day)) {
      age--;
    }
    return '$age anos';
  }

  String? _calculateBMI() {
    if (_weight == null || _height == null) return null;
    final heightInMeters = _height! / 100;
    final bmi = _weight! / (heightInMeters * heightInMeters);
    return bmi.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações do usuário
                    Text(
                      'Nome: $_name',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'E-mail: $_email',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    // Verifica se informações básicas estão definidas
                    if (_weight == null ||
                        _height == null ||
                        _gender == null ||
                        _birthDate == null)
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Complete suas informações:',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),

                            // Campo de Peso
                            TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Peso (kg)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira seu peso';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Insira um número válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Campo de Altura
                            TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Altura (cm)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira sua altura';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Insira um número válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Campo de Sexo
                            DropdownButtonFormField<String>(
                              value: _gender,
                              decoration: const InputDecoration(
                                labelText: 'Sexo',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'M', child: Text('Masculino')),
                                DropdownMenuItem(value: 'F', child: Text('Feminino')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _gender = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Por favor, selecione seu sexo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Campo de Data de Nascimento
                            TextFormField(
                              controller: _birthDateController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Data de Nascimento',
                                border: OutlineInputBorder(),
                              ),
                              onTap: () async {
                                final selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(2000),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (selectedDate != null) {
                                  setState(() {
                                    _birthDateController.text =
                                        DateFormat('dd/MM/yyyy').format(selectedDate);
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira sua data de nascimento';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Botão de Salvar
                            ElevatedButton(
                              onPressed: _saveUserInfo,
                              child: const Text('Salvar'),
                            ),
                          ],
                        ),
                      )
                    else
                      // Exibe informações do usuário
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Peso: ${_weight!.toStringAsFixed(1)} kg',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Altura: ${_height!.toStringAsFixed(1)} cm',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sexo: ${_gender == 'M' ? 'Masculino' : 'Feminino'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Idade: ${_calculateAge()}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'IMC: ${_calculateBMI()}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
