import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const AppointmentHistoryScreen({
    super.key,
    required this.themeProvider,
  });

  @override
  State<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen>
    with TickerProviderStateMixin {
  String _userRole = 'patient';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserRole();
    // Mark past appointments as missed when the screen loads
    AppointmentService.markPastAppointmentsAsMissed();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userRole = doc.data()?['role'] ?? 'patient';
          });
        }
      }
    } catch (e) {
      print('Error loading user role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(
          child: Text(
            'Please log in to view appointment history',
            style: TextStyle(color: theme.textColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Appointment History',
          style: TextStyle(
            color: theme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.subtextColor,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Completed'),
            Tab(text: 'Missed'),
            Tab(text: 'Canceled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentsList(user.uid, 'all', theme),
          _buildAppointmentsList(user.uid, 'completed', theme),
          _buildAppointmentsList(user.uid, 'missed', theme),
          _buildAppointmentsList(user.uid, 'canceled', theme),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(String userId, String filter, ThemeProvider theme) {
    Stream<List<Appointment>> appointmentsStream;

    switch (filter) {
      case 'completed':
        appointmentsStream = AppointmentService.getAllAppointments(userId, _userRole)
            .map((appointments) => appointments.where((a) => a.status == 'completed').toList());
        break;
      case 'missed':
        appointmentsStream = AppointmentService.getMissedAppointments(userId, _userRole);
        break;
      case 'canceled':
        appointmentsStream = AppointmentService.getAllAppointments(userId, _userRole)
            .map((appointments) => appointments.where((a) => a.status == 'canceled').toList());
        break;
      default:
        appointmentsStream = AppointmentService.getAllAppointments(userId, _userRole);
    }

    return StreamBuilder<List<Appointment>>(
      stream: appointmentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: theme.primaryColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.subtextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading appointments',
                  style: TextStyle(
                    fontSize: 18,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.subtextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getEmptyStateIcon(filter),
                  size: 64,
                  color: theme.subtextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyStateTitle(filter),
                  style: TextStyle(
                    fontSize: 18,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptyStateMessage(filter),
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.subtextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return _buildAppointmentCard(appointment, theme);
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, ThemeProvider theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.formattedDate,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.formattedTime,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(appointment.status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    appointment.statusDisplayText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(appointment.status),
                    ),
                  ),
                ),
              ],
            ),
            
            if (appointment.purpose.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.note_rounded,
                    size: 16,
                    color: theme.subtextColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.purpose,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Relative time
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: theme.subtextColor,
                ),
                const SizedBox(width: 8),
                Text(
                  appointment.relativeTimeString,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.subtextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEmptyStateIcon(String filter) {
    switch (filter) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'missed':
        return Icons.event_busy_rounded;
      case 'canceled':
        return Icons.cancel_outlined;
      default:
        return Icons.event_note_rounded;
    }
  }

  String _getEmptyStateTitle(String filter) {
    switch (filter) {
      case 'completed':
        return 'No completed appointments';
      case 'missed':
        return 'No missed appointments';
      case 'canceled':
        return 'No canceled appointments';
      default:
        return 'No appointment history';
    }
  }

  String _getEmptyStateMessage(String filter) {
    switch (filter) {
      case 'completed':
        return 'Your completed appointments will appear here.';
      case 'missed':
        return 'Great job! You haven\'t missed any appointments.';
      case 'canceled':
        return 'You haven\'t canceled any appointments.';
      default:
        return 'Your appointment history will appear here.';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'canceled':
        return Colors.red;
      case 'missed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
