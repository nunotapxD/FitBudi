import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // You need to add the table_calendar package to your pubspec.yaml

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Calendar"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TableCalendar(
              focusedDay: DateTime.now(),
              firstDay: DateTime.utc(2020, 01, 01),
              lastDay: DateTime.utc(2025, 12, 31),
              onDaySelected: (selectedDay, focusedDay) {
                print(selectedDay); // You can handle day selection here.
              },
            ),
          ],
        ),
      ),
    );
  }
}