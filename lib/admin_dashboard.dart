import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userName; // To store the authenticated user's name
  List<Map<String, dynamic>> users = []; // To store other users' data
  List<Map<String, dynamic>> deletedUsers = []; // To store deleted users
  String? selectedUserId; // To store the selected user's UID
  bool showDeletedUsers = false; // To track whether deleted users are being shown
  List<Map<String, dynamic>> calendarEvents = []; // To store calendar events

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUsers();
  }

  // Fetch data for the authenticated user
  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        userName = userDoc['name']; // Get the name of the authenticated user
        selectedUserId = user.uid; // Set the authenticated user's ID as selected by default
      });
    }
  }

  // Fetch all users (excluding the current authenticated user)
  Future<void> _fetchUsers() async {
    QuerySnapshot querySnapshot = await _firestore.collection('users').get();
    setState(() {
      users = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((user) => user['uid'] != _auth.currentUser?.uid && user['deleted'] != 1) // Exclude the authenticated user and deleted users
          .toList();
    });
  }

  // Fetch deleted users (users with 'deleted' field set to 1)
  Future<void> _fetchDeletedUsers() async {
    QuerySnapshot querySnapshot = await _firestore.collection('users').where('deleted', isEqualTo: 1).get();
    setState(() {
      deletedUsers = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      showDeletedUsers = true; // Set to true when showing deleted users
    });
  }

  // Fetch calendar events for all users
  Future<void> _fetchCalendarEvents() async {
    // Fetch the calendar subcollections for all users
    List<Map<String, dynamic>> events = [];
    for (var user in users) {
      var userId = user['uid'];
      QuerySnapshot calendarSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('calendar')
          .get();

      events.addAll(calendarSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList());
    }

    setState(() {
      calendarEvents = events; // Store the fetched calendar events
    });
  }

  // Mark a user as deleted (soft delete)
  Future<void> _deleteUser(String userId) async {
    if (_auth.currentUser?.uid != userId) { // Prevent deletion of the authenticated user
      await _firestore.collection('users').doc(userId).update({'deleted': 1});
      _fetchUsers(); // Refresh the user list
    }
  }

  // Restore a deleted user
  Future<void> _restoreUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({'deleted': 0});
    _fetchDeletedUsers(); // Refresh the deleted users list
    _fetchUsers(); // Refresh the user list
  }

  // Update the selected user's UID and trigger calendar update
  void _onUserTap(String userId) {
    setState(() {
      selectedUserId = userId; // Set the selected user's UID
      showDeletedUsers = false; // Reset deleted users view
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: Row(
        children: [
          // Left Sidebar
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[200],
              child: Column(
                children: [
                  // Display authenticated user's name at the top
                  ListTile(
                    title: Text(userName ?? 'Loading...'), // Display authenticated user's name
                    subtitle: Text('Authenticated User'),
                    tileColor: Colors.blue[100],
                    onTap: () {
                      _onUserTap(_auth.currentUser!.uid); // Set the authenticated user as selected
                    },
                  ),
                  Divider(),
                  // Display other users below the authenticated user
                  ...users.map((user) {
                    return ListTile(
                      title: Text(user['name']), // Display the name of the other users
                      subtitle: Text(user['email'] ?? 'No email'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteUser(user['uid']),
                      ),
                      onTap: () {
                        _onUserTap(user['uid']); // Update selected user when clicked
                      },
                    );
                  }).toList(),
                  Spacer(),
                  // Deleted Users Button
                  ElevatedButton(
                    onPressed: () {
                      _fetchDeletedUsers();
                    },
                    child: Text('Show Deleted Users'),
                  ),
                ],
              ),
            ),
          ),
          // Right Section (Calendar or Deleted Users List)
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Only display the title when not showing deleted users
                  if (!showDeletedUsers) ...[
                    Text('Calendar of Events', style: TextStyle(fontSize: 20)),
                    ElevatedButton(
                      onPressed: _fetchCalendarEvents, // Fetch all calendar events for users
                      child: Text('Fetch All Calendar Events'),
                    ),
                  ],
                  Expanded(
                    child: showDeletedUsers
                        ? ListView.builder(
                            itemCount: deletedUsers.length,
                            itemBuilder: (context, index) {
                              final user = deletedUsers[index];
                              return ListTile(
                                title: Text(user['name']),
                                subtitle: Text(user['email'] ?? 'No email'),
                                trailing: IconButton(
                                  icon: Icon(Icons.restore),
                                  onPressed: () => _restoreUser(user['uid']),
                                ),
                              );
                            },
                          )
                        : selectedUserId == null
                            ? Center(child: Text('Please select a user'))
                            : UserCalendarWidget(userId: selectedUserId!), // Show calendar for the selected user
                  ),
                  // Display calendar events as a list
                  if (calendarEvents.isNotEmpty) ...[
                    Text('All Calendar Events:', style: TextStyle(fontSize: 18)),
                    Expanded(
                      child: ListView.builder(
                        itemCount: calendarEvents.length,
                        itemBuilder: (context, index) {
                          final event = calendarEvents[index];
                          return ListTile(
                            title: Text(event['type'] ?? 'Event'),
                            subtitle: Text(
                                'Start: ${event['startDate']} - End: ${event['endDate']}'),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Calendar Widget for the selected user
class UserCalendarWidget extends StatelessWidget {
  final String userId;

  UserCalendarWidget({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Calendar events for user ID $userId')); // Placeholder for user-specific calendar
  }
}
