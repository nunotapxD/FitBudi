import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class UserCalendarWidget extends StatefulWidget {
  final String userId;
  final bool isAdmin;

  const UserCalendarWidget({
    Key? key,
    required this.userId,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<UserCalendarWidget> createState() => _UserCalendarWidgetState();
}

class _UserCalendarWidgetState extends State<UserCalendarWidget> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('meals')
        .get();

    final newEvents = <DateTime, List<Map<String, dynamic>>>{};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final dateKey = DateTime(date.year, date.month, date.day);

      if (!newEvents.containsKey(dateKey)) {
        newEvents[dateKey] = [];
      }
      newEvents[dateKey]!.add({
        ...data,
        'id': doc.id,
      });
    }

    if (mounted) {
      setState(() {
        _events = newEvents;
      });
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: _getEventsForDay,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildEventList(),
        ),
      ],
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay);

    if (events.isEmpty) {
      return const Center(
        child: Text('Nenhuma refeição registrada para este dia'),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          child: ListTile(
            title: Text(event['mealName'] ?? ''),
            subtitle: Text(
              '${event['mealType']} - ${event['time']}\n'
              'Calorias: ${event['calories']} kcal | '
              'P: ${event['protein']}g | '
              'C: ${event['carbs']}g | '
              'G: ${event['fats']}g',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}