import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _WeightHistory {
  final DateTime date;
  final double weight;

  _WeightHistory({required this.date, required this.weight});
}

class _ProfilePageState extends State<ProfilePage> {
  // Instâncias do Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variáveis de estado do usuário
  User? _user;
  String _name = '';
  String _email = '';
  double? _weight;
  double? _height;
  String? _gender;
  DateTime? _birthDate;
  bool _isLoading = true;

  // Lista para armazenar histórico de peso
  List<_WeightHistory> _weightHistory = [];

  // Controllers para formulários
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Método para buscar dados do usuário
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Busca usuário atual
      _user = _auth.currentUser;
      if (_user != null) {
        // Busca nome e email
        _name = _user!.displayName ?? 'Usuário';
        _email = _user!.email ?? 'Sem e-mail';

        // Busca dados adicionais no Firestore
        final doc = await _firestore.collection('users').doc(_user!.uid).get();
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _weight = data?['weight']?.toDouble();
            _height = data?['height']?.toDouble();
            _gender = data?['gender'];
            _birthDate = data?['birthDate'] != null
                ? (data!['birthDate'] as Timestamp).toDate()
                : null;
          });

          // Busca histórico de peso
          await _fetchWeightHistory();
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar informações: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Método para buscar histórico de peso
  Future<void> _fetchWeightHistory() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('weightHistory')
          .orderBy('date')
          .get();

      setState(() {
        _weightHistory = querySnapshot.docs.map((doc) {
          return _WeightHistory(
            date: (doc['date'] as Timestamp).toDate(),
            weight: doc['weight'].toDouble(),
          );
        }).toList();
      });
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar histórico de peso: $e');
    }
  }

  // Método para salvar informações do usuário
  Future<void> _saveUserInfo() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Parse dos dados do formulário
        final weight = double.parse(_weightController.text);
        final height = double.parse(_heightController.text);
        final gender = _gender!;
        final birthDate = DateFormat('dd/MM/yyyy').parse(_birthDateController.text);

        // Salva no Firestore
        await _firestore.collection('users').doc(_user!.uid).set({
          'weight': weight,
          'height': height,
          'gender': gender,
          'birthDate': birthDate,
        }, SetOptions(merge: true));

        // Adiciona primeira entrada de peso ao histórico
        await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('weightHistory')
          .add({
            'date': DateTime.now(),
            'weight': weight,
          });

        // Atualiza estado local
        setState(() {
          _weight = weight;
          _height = height;
          _gender = gender;
          _birthDate = birthDate;
          _weightHistory.add(_WeightHistory(
            date: DateTime.now(), 
            weight: weight
          ));
        });

        _showSuccessSnackBar('Dados salvos com sucesso!');
      } catch (e) {
        _showErrorSnackBar('Erro ao salvar os dados: $e');
      }
    }
  }


  // Métodos auxiliares de cálculo
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

  // Métodos de exibição de mensagens
void _showErrorSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}
void _showSuccessSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ),
  );
}
  // Método para construir gráfico de peso
Widget _buildWeightChart() {
  return StreamBuilder<QuerySnapshot>(
    stream: _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('weight_history')
        .orderBy('date')
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
      }

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final weightHistory = snapshot.data?.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _WeightHistory(
          date: (data['date'] as Timestamp).toDate(),
          weight: data['weight'].toDouble(),
        );
      }).toList() ?? [];

      if (weightHistory.isEmpty) {
        return const Center(child: Text('Sem dados de peso'));
      }

      final minWeight = weightHistory.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
      final maxWeight = weightHistory.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
      final padding = (maxWeight - minWeight) * 0.1;

      return SizedBox(
        height: 300,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 2,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= weightHistory.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('dd/MM').format(weightHistory[index].date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 2,
                  reservedSize: 45,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            minX: 0,
            maxX: (weightHistory.length - 1).toDouble(),
            minY: minWeight - padding,
            maxY: maxWeight + padding,
            lineBarsData: [
              LineChartBarData(
                spots: weightHistory.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value.weight,
                  );
                }).toList(),
                isCurved: true,
                color: Colors.blue.shade500,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => 
                    FlDotCirclePainter(
                      radius: 4,
                      color: Colors.blue.shade500,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.shade200.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações básicas do usuário
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

                    // Exibe informações do usuário ou formulário para preenchimento
                    if (_weight == null || _height == null || _gender == null || _birthDate == null)
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
                          const SizedBox(height: 24),
                          const Text(
                            'Histórico de Peso:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: _buildWeightChart(),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}