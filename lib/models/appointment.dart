import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String? id;
  final String doctorId;
  final String patientId;
  final DateTime date;
  final String time;
  final String purpose;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? rescheduleRequestedBy; // Track who requested the reschedule

  Appointment({
    this.id,
    required this.doctorId,
    required this.patientId,
    required this.date,
    required this.time,
    required this.purpose,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.rescheduleRequestedBy,
  });

  // Convert Appointment to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'date': Timestamp.fromDate(date),
      'time': time,
      'purpose': purpose,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'rescheduleRequestedBy': rescheduleRequestedBy,
    };
  }

  // Create Appointment from Firestore document
  factory Appointment.fromMap(Map<String, dynamic> map, String documentId) {
    return Appointment(
      id: documentId,
      doctorId: map['doctorId'] ?? '',
      patientId: map['patientId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      time: map['time'] ?? '',
      purpose: map['purpose'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      rescheduleRequestedBy: map['rescheduleRequestedBy'],
    );
  }

  // Create a copy of Appointment with updated fields
  Appointment copyWith({
    String? id,
    String? doctorId,
    String? patientId,
    DateTime? date,
    String? time,
    String? purpose,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? rescheduleRequestedBy,
  }) {
    return Appointment(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      date: date ?? this.date,
      time: time ?? this.time,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rescheduleRequestedBy: rescheduleRequestedBy ?? this.rescheduleRequestedBy,
    );
  }

  // Get appointment status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA500'; // Orange
      case 'confirmed':
        return '#4CAF50'; // Green
      case 'completed':
        return '#2196F3'; // Blue
      case 'canceled':
        return '#F44336'; // Red
      case 'missed':
        return '#9C27B0'; // Purple
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Get appointment status display text
  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'canceled':
        return 'Canceled';
      case 'missed':
        return 'Missed';
      default:
        return 'Unknown';
    }
  }

  // Check if appointment is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    final appointmentDateTime = DateTime(date.year, date.month, date.day);
    return appointmentDateTime.isAfter(now) || appointmentDateTime.isAtSameMomentAs(now);
  }

  // Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    final appointmentDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    return appointmentDate.isAtSameMomentAs(today);
  }

  // Check if appointment is in the past
  bool get isPast {
    final now = DateTime.now();
    final appointmentDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    return appointmentDate.isBefore(today);
  }

  // Check if appointment should be marked as missed
  bool get shouldBeMarkedAsMissed {
    return isPast && 
           status != 'completed' && 
           status != 'canceled' && 
           status != 'missed';
  }

  // Check if appointment is completed or canceled (final states)
  bool get isFinalState {
    return status == 'completed' || status == 'canceled' || status == 'missed';
  }

  // Get formatted date string
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Get formatted time string
  String get formattedTime {
    return time;
  }

  // Get relative time string (e.g., "Today", "Tomorrow", "In 3 days")
  String get relativeTimeString {
    final now = DateTime.now();
    final appointmentDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = appointmentDate.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference > 1) {
      return 'In $difference days';
    } else if (difference == -1) {
      return 'Yesterday';
    } else {
      return '${difference.abs()} days ago';
    }
  }
}
