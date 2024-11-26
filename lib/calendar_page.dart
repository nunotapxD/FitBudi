import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_service.dart';

class CalendarPage extends StatefulWidget {
  final String userId;
  final bool isAdmin;
  
  const CalendarPage({
    super.key, 
    required this.userId,
    required this.isAdmin,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _firebaseService = FirebaseService.instance;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  String _userName = 'Usuário';

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _loadUserName();
    _loadEvents();
  }

  Future<void> _loadUserName() async {
    final name = await _firebaseService.getUserName(widget.userId);
    if (mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  Future<void> _loadEvents() async {
    final start = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final end = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);
    
    try {
      final events = await _firebaseService.getEventsByDateRange(
        userId: widget.userId,
        start: start,
        end: end,
      );
      
      if (mounted) {
        setState(() {
          _events = _groupEventsByDate(events);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar eventos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<DateTime, List<Event>> _groupEventsByDate(List<Event> events) {
    Map<DateTime, List<Event>> groupedEvents = {};
    
    for (var event in events) {
      if (event.date != null) {
        final dateKey = DateTime(
          event.date!.year,
          event.date!.month,
          event.date!.day,
        );
        
        if (!groupedEvents.containsKey(dateKey)) {
          groupedEvents[dateKey] = [];
        }
        
        groupedEvents[dateKey]!.add(event);
      }
    }
    
    return groupedEvents;
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _showAddEventDialog(DateTime selectedDate) {
    if (!widget.isAdmin) return;

    final timeController = TextEditingController();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String eventType = 'Treino';
    bool emailNotification = true;
    bool pushNotification = true;
    int reminderTime = 30;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Adicionar Evento para $_userName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: eventType,
                  decoration: const InputDecoration(labelText: 'Tipo de Evento'),
                  items: ['Treino', 'Consulta', 'Avaliação']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => eventType = value!);
                  },
                ),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Horário (HH:mm)',
                    hintText: '14:30',
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text('Notificações', 
                  style: TextStyle(fontWeight: FontWeight.bold)
                ),
                CheckboxListTile(
                  title: const Text('Email'),
                  value: emailNotification,
                  onChanged: (value) {
                    setState(() => emailNotification = value!);
                  },
                ),
                CheckboxListTile(
                  title: const Text('Push'),
                  value: pushNotification,
                  onChanged: (value) {
                    setState(() => pushNotification = value!);
                  },
                ),
                DropdownButtonFormField<int>(
                  value: reminderTime,
                  decoration: const InputDecoration(
                    labelText: 'Lembrete (minutos antes)'
                  ),
                  items: [15, 30, 60, 120]
                      .map((minutes) => DropdownMenuItem(
                            value: minutes,
                            child: Text('$minutes minutos'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => reminderTime = value!),
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
                if (titleController.text.isNotEmpty && 
                    timeController.text.isNotEmpty) {
                  try {
                    await _firebaseService.createEvent(
                      userId: widget.userId,
                      title: titleController.text,
                      description: descriptionController.text,
                      date: selectedDate,
                      time: timeController.text,
                      type: eventType,
                      notifications: {
                        'email': emailNotification,
                        'push': pushNotification,
                        'reminderTime': reminderTime,
                      },
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      _loadEvents();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Evento criado com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao criar evento: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preencha todos os campos obrigatórios'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda'),
        actions: widget.isAdmin ? [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEventDialog(_selectedDay ?? _focusedDay),
          ),
        ] : null,
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: const CalendarStyle(
              markersMaxCount: 3,
              markerSize: 8.0,
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadEvents();
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Selecione um dia'))
                : _buildEventsList(_getEventsForDay(_selectedDay!)),
          ),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: () => _showAddEventDialog(_selectedDay ?? _focusedDay),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEventsList(List<Event> events) {
    if (events.isEmpty) {
      return const Center(
        child: Text('Nenhum evento para este dia'),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          child: ListTile(
            leading: Icon(
              event.type == 'Treino'
                  ? Icons.fitness_center
                  : event.type == 'Consulta'
                      ? Icons.medical_services
                      : Icons.assessment,
              color: Colors.blue,
            ),
            title: Text(event.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${event.time} - ${event.description}'),
                if (widget.isAdmin && event.createdAt != null)
                  Text(
                    'Criado em: ${_formatDateTime(event.createdAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            isThreeLine: widget.isAdmin,
            trailing: widget.isAdmin
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edição em desenvolvimento'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteConfirmDialog(event),
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente excluir este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await _firebaseService.cancelEvent(
                  userId: widget.userId,
                  eventId: event.id,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadEvents();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Evento excluído com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir evento: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}