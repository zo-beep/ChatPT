import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment.dart';

class AppointmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new appointment
  static Future<String> createAppointment(Appointment appointment) async {
    try {
      final docRef = await _firestore.collection('appointments').add(appointment.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating appointment: $e');
      throw Exception('Failed to create appointment');
    }
  }

  // Reschedule an appointment
  static Future<void> rescheduleAppointment(String appointmentId, DateTime newDate, String newTime, String userRole) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Set status to pending for confirmation when rescheduled
      // Patient rescheduling needs doctor confirmation, doctor rescheduling needs patient confirmation
      await _firestore.collection('appointments').doc(appointmentId).update({
        'date': Timestamp.fromDate(newDate),
        'time': newTime,
        'status': 'pending', // Always set to pending for confirmation
        'rescheduleRequestedBy': currentUser.uid, // Track who requested the reschedule
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error rescheduling appointment: $e');
      throw Exception('Failed to reschedule appointment');
    }
  }

  // Mark an appointment as completed
  static Future<void> markAppointmentAsCompleted(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking appointment as completed: $e');
      throw Exception('Failed to mark appointment as completed');
    }
  }

  // Delete an appointment
  static Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).delete();
    } catch (e) {
      print('Error deleting appointment: $e');
      throw Exception('Failed to delete appointment');
    }
  }

  // Get appointments for a specific doctor
  static Stream<List<Appointment>> getDoctorAppointments(String doctorId) {
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs.map((doc) {
        return Appointment.fromMap(doc.data(), doc.id);
      }).toList();
      
      // Sort by date and time locally
      appointments.sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        return a.time.compareTo(b.time);
      });
      
      return appointments;
    });
  }

  // Get appointments for a specific patient
  static Stream<List<Appointment>> getPatientAppointments(String patientId) {
    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs.map((doc) {
        return Appointment.fromMap(doc.data(), doc.id);
      }).toList();
      
      // Sort by date and time locally
      appointments.sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        return a.time.compareTo(b.time);
      });
      
      return appointments;
    });
  }

  // Get upcoming appointments for a user (doctor or patient)
  static Stream<List<Appointment>> getUpcomingAppointments(String userId, String userRole) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _firestore
        .collection('appointments')
        .where(userRole == 'doctor' ? 'doctorId' : 'patientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs.map((doc) {
        return Appointment.fromMap(doc.data(), doc.id);
      }).toList();
      
      // Filter for upcoming appointments and sort locally
      final upcomingAppointments = appointments.where((appointment) {
        final appointmentDate = DateTime(appointment.date.year, appointment.date.month, appointment.date.day);
        // Exclude completed appointments regardless of date
        return (appointmentDate.isAfter(today) || appointmentDate.isAtSameMomentAs(today)) 
               && appointment.status != 'completed';
      }).toList();
      
      upcomingAppointments.sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        return a.time.compareTo(b.time);
      });
      
      return upcomingAppointments;
    });
  }

  // Get past appointments for a user (doctor or patient)
  static Stream<List<Appointment>> getPastAppointments(String userId, String userRole) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _firestore
        .collection('appointments')
        .where(userRole == 'doctor' ? 'doctorId' : 'patientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs.map((doc) {
        return Appointment.fromMap(doc.data(), doc.id);
      }).toList();
      
      // Filter for past appointments and sort locally
      final pastAppointments = appointments.where((appointment) {
        final appointmentDate = DateTime(appointment.date.year, appointment.date.month, appointment.date.day);
        return appointmentDate.isBefore(today);
      }).toList();
      
      pastAppointments.sort((a, b) {
        final dateCompare = b.date.compareTo(a.date); // Sort by most recent first
        if (dateCompare != 0) return dateCompare;
        return b.time.compareTo(a.time);
      });
      
      return pastAppointments;
    });
  }

  // Get all appointments for a user (doctor or patient) - includes past and upcoming
  static Stream<List<Appointment>> getAllAppointments(String userId, String userRole) {
    return _firestore
        .collection('appointments')
        .where(userRole == 'doctor' ? 'doctorId' : 'patientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs.map((doc) {
        return Appointment.fromMap(doc.data(), doc.id);
      }).toList();
      
      // Sort by date (most recent first)
      appointments.sort((a, b) {
        final dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) return dateCompare;
        return b.time.compareTo(a.time);
      });
      
      return appointments;
    });
  }

  // Automatically mark past appointments as missed
  static Future<void> markPastAppointmentsAsMissed() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get all appointments that are in the past and not in final states
      final querySnapshot = await _firestore
          .collection('appointments')
          .get();
      
      final batch = _firestore.batch();
      bool hasUpdates = false;
      
      for (var doc in querySnapshot.docs) {
        final appointment = Appointment.fromMap(doc.data(), doc.id);
        
        if (appointment.shouldBeMarkedAsMissed) {
          batch.update(doc.reference, {
            'status': 'missed',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          hasUpdates = true;
        }
      }
      
      if (hasUpdates) {
        await batch.commit();
        print('Marked past appointments as missed');
      }
    } catch (e) {
      print('Error marking past appointments as missed: $e');
    }
  }

  // Get today's appointments for a user
  static Stream<List<Appointment>> getTodaysAppointments(String userId, String userRole) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _firestore
        .collection('appointments')
        .where(userRole == 'doctor' ? 'doctorId' : 'patientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs.map((doc) {
        return Appointment.fromMap(doc.data(), doc.id);
      }).toList();
      
      // Filter for today's appointments and sort locally
      final todaysAppointments = appointments.where((appointment) {
        final appointmentDate = DateTime(appointment.date.year, appointment.date.month, appointment.date.day);
        return appointmentDate.isAtSameMomentAs(today);
      }).toList();
      
      todaysAppointments.sort((a, b) {
        return a.time.compareTo(b.time);
      });
      
      return todaysAppointments;
    });
  }

  // Get missed appointments for a user
  static Stream<List<Appointment>> getMissedAppointments(String userId, String userRole) {
    return _firestore
        .collection('appointments')
        .where(userRole == 'doctor' ? 'doctorId' : 'patientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs.map((doc) {
        return Appointment.fromMap(doc.data(), doc.id);
      }).toList();
      
      // Filter for missed appointments and sort locally
      final missedAppointments = appointments.where((appointment) {
        return appointment.status == 'missed';
      }).toList();
      
      missedAppointments.sort((a, b) {
        final dateCompare = b.date.compareTo(a.date); // Sort by most recent first
        if (dateCompare != 0) return dateCompare;
        return b.time.compareTo(a.time);
      });
      
      return missedAppointments;
    });
  }

  // Check for appointment conflicts
  static Future<bool> hasConflict(String doctorId, DateTime date, String time, {String? excludeAppointmentId}) async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      // Filter locally for conflicts
      final appointments = querySnapshot.docs.map((doc) {
        return Appointment.fromMap(doc.data(), doc.id);
      }).toList();

      final conflictAppointments = appointments.where((appointment) {
        final appointmentDate = DateTime(appointment.date.year, appointment.date.month, appointment.date.day);
        final checkDate = DateTime(date.year, date.month, date.day);
        
        return appointmentDate.isAtSameMomentAs(checkDate) &&
               appointment.time == time &&
               (appointment.status == 'pending' || appointment.status == 'confirmed') &&
               appointment.id != excludeAppointmentId; // Exclude the appointment being rescheduled
      }).toList();

      return conflictAppointments.isNotEmpty;
    } catch (e) {
      print('Error checking for conflicts: $e');
      return false;
    }
  }

  // Get all patients for a doctor (for appointment creation)
  static Future<List<Map<String, dynamic>>> getDoctorPatients(String doctorId) async {
    try {
      // First, try to get the doctor's name for comparison
      final doctorDoc = await _firestore.collection('users').doc(doctorId).get();
      String? doctorName;
      if (doctorDoc.exists) {
        doctorName = doctorDoc.data()?['name'];
      }

      // Query for all users except doctors
      final querySnapshot = await _firestore
          .collection('users')
          .get();

      List<Map<String, dynamic>> patients = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        // Skip users with doctor role
        if (data['role'] == 'doctor') continue;
        
        final assignedDoctor = data['assignedDoctor'];
        
        // Check if this patient is assigned to the current doctor
        // The assignedDoctor field might contain either:
        // 1. The doctor's ID
        // 2. The doctor's name
        // 3. Be empty/null (show all patients as fallback)
        bool isAssignedToDoctor = false;
        
        if (assignedDoctor != null && assignedDoctor.toString().isNotEmpty) {
          // Check if assignedDoctor matches doctor ID or doctor name
          isAssignedToDoctor = assignedDoctor.toString() == doctorId || 
                              (doctorName != null && assignedDoctor.toString() == doctorName);
        } else {
          // If no assignedDoctor is set, include all patients (fallback)
          isAssignedToDoctor = true;
        }

        if (isAssignedToDoctor) {
          patients.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown',
            'email': data['email'] ?? '',
            'contactNumber': data['contactNumber'] ?? '',
            'assignedDoctor': assignedDoctor?.toString() ?? '',
          });
        }
      }

      return patients;
    } catch (e) {
      print('Error getting doctor patients: $e');
      return [];
    }
  }

  // Get doctor information for a patient
  static Future<Map<String, dynamic>?> getDoctorInfo(String doctorId) async {
    try {
      final doc = await _firestore.collection('users').doc(doctorId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Doctor',
          'email': data['email'] ?? '',
          'specialization': data['specialization'] ?? '',
          'contactNumber': data['contactNumber'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Error getting doctor info: $e');
      return null;
    }
  }

  // Update appointment status
  static Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Clear rescheduleRequestedBy when appointment is confirmed or rejected
      if (status == 'confirmed' || status == 'canceled') {
        updateData['rescheduleRequestedBy'] = FieldValue.delete();
      }
      
      await _firestore.collection('appointments').doc(appointmentId).update(updateData);
    } catch (e) {
      print('Error updating appointment status: $e');
      throw Exception('Failed to update appointment status');
    }
  }

  // Get appointment statistics for a doctor
  static Future<Map<String, int>> getDoctorAppointmentStats(String doctorId) async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final stats = {
        'total': 0,
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'canceled': 0,
      };

      for (final doc in querySnapshot.docs) {
        final appointment = Appointment.fromMap(doc.data(), doc.id);
        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[appointment.status] = (stats[appointment.status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Error getting appointment stats: $e');
      return {
        'total': 0,
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'canceled': 0,
      };
    }
  }
}
