import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

// Import the pages
import 'calendar_page.dart';
import 'meals_page.dart';
import 'videos_page.dart';
import 'chat_page.dart';
import 'settings_page.dart';

class ClientDashboardPage extends StatelessWidget {
  const ClientDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView( // Allow scrolling if content overflows
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // First row of squares (Date and Meal)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDashboardSquareWithDate(context),  // Calendar tile with today's date
                  SizedBox(width: 20), // Space between squares
                  _buildDashboardSquare(context, 'Meal', '/meals'),
                ],
              ),
              SizedBox(height: 20), // Space between rows

              // Second row of squares (Videos and Info)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDashboardSquare(context, 'Videos', '/videos'),
                  SizedBox(width: 20), // Space between squares
                  _buildDashboardSquare(context, 'Info', '/info'),
                ],
              ),
              SizedBox(height: 20), // Space between rows

              // Third row of squares (Chat and Settings)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDashboardSquare(context, 'Chat', '/chat'),
                  SizedBox(width: 20), // Space between squares
                  _buildDashboardSquare(context, 'Settings', '/settings'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build the dashboard square tile
  Widget _buildDashboardSquare(BuildContext context, String title, String route) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);  // Navigate to the page on tap
      },
      child: Container(
        width: 150.0,  // Fixed width
        height: 150.0, // Fixed height
        decoration: BoxDecoration(
          color: Colors.blueAccent, // Consistent color for all squares
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 2, blurRadius: 6),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // Function to build the Calendar tile with today's date
  Widget _buildDashboardSquareWithDate(BuildContext context) {
    DateTime now = DateTime.now();
    String month = DateFormat('MMMM').format(now).toLowerCase(); // Get month in lowercase
    String day = DateFormat('d').format(now); // Get day number
    String weekday = DateFormat('EEEE').format(now); // Get day of the week

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/calendar');  // Navigate to the Calendar page
      },
      child: Container(
        width: 150.0,  // Fixed width
        height: 150.0, // Fixed height
        decoration: BoxDecoration(
          color: Colors.blueAccent, // Consistent color for all squares
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 2, blurRadius: 6),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              month,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              day,
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              weekday,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
