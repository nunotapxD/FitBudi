import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final FirebaseService instance = FirebaseService._internal();
  
  FirebaseService._internal();

  Future<void> createEvent({
    required String userId,  // Este é o usuário selecionado
    required String title,
    required String description,
    required DateTime date,
    required String time,
    required String type,
    required Map<String, dynamic> notifications,
  }) async {
    try {
      // Pegamos o ID do admin atual que está criando o evento
      final String? adminId = _auth.currentUser?.uid;
      if (adminId == null) {
        throw Exception('Admin não autenticado');
      }

      await _firestore
          .collection('users')
          .doc(userId) // Usando o ID do usuário selecionado
          .collection('events')
          .add({
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date),
        'time': time,
        'type': type,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': adminId, // ID do admin que está criando
        'adminName': await _getAdminName(adminId), // Nome do admin para referência
        'notifications': notifications,
      });
    } catch (e) {
      throw Exception('Erro ao criar evento: $e');
    }
  }

  Future<String> getUserName(String userId) async {
  try {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['name'] as String? ?? 'Usuário';
    }
    return 'Usuário';
  } catch (e) {
    return 'Usuário';
  }
}

  // Método auxiliar para buscar o nome do admin
  Future<String> _getAdminName(String adminId) async {
    try {
      final adminDoc = await _firestore.collection('users').doc(adminId).get();
      return (adminDoc.data() as Map<String, dynamic>)['name'] as String? ?? 'Admin';
    } catch (e) {
      return 'Admin';
    }
  }

  Future<void> updateEvent({
    required String userId,
    required String eventId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('events')
          .doc(eventId)
          .update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
    } catch (e) {
      throw Exception('Erro ao atualizar evento: $e');
    }
  }

  Future<void> cancelEvent({
    required String userId,
    required String eventId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('events')
          .doc(eventId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
    } catch (e) {
      throw Exception('Erro ao cancelar evento: $e');
    }
  }

  // Modificado para não usar o índice composto
  Stream<List<Event>> getEventsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Event.fromFirestore(doc))
              .where((event) => event.status == 'active')
              .toList();
        });
  }

  // Modificado para não usar o índice composto
  Future<List<Event>> getEventsByDateRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('date')
          .get();

      return snapshot.docs
          .map((doc) => Event.fromFirestore(doc))
          .where((event) => event.status == 'active')
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar eventos: $e');
    }
  }

  Future<void> createNotification({
    required String userId,
    required String eventId,
    required String title,
    required String message,
    required DateTime scheduledFor,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'eventId': eventId,
        'title': title,
        'message': message,
        'scheduledFor': Timestamp.fromDate(scheduledFor),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao criar notificação: $e');
    }
  }
}

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String type;
  final String status;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;
  final Map<String, dynamic> notifications;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
    this.updatedBy,
    required this.notifications,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      type: data['type'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'],
      notifications: data['notifications'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'time': time,
      'type': type,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'updatedBy': updatedBy,
      'notifications': notifications,
    };
  }
}