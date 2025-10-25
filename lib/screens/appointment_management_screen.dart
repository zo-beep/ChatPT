import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import 'create_appointment_screen.dart';
import 'reschedule_appointment_screen.dart';

class AppointmentManagementScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const AppointmentManagementScreen({
    super.key,
    required this.themeProvider,
  });

  @override
  State<AppointmentManagementScreen> createState() => _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState extends State<AppointmentManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Mark past appointments as missed when the screen loads
    AppointmentService.markPastAppointmentsAsMissed();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            'User not authenticated',
            style: TextStyle(color: theme.textColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Appointments',
          style: TextStyle(color: theme.primaryColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: theme.primaryColor),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateAppointmentScreen(
                    themeProvider: theme,
                  ),
                ),
              );
              if (result == true) {
                // Refresh the screen if appointment was created
                setState(() {});
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.subtextColor,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Missed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentsList(user.uid, 'all', theme),
          _buildAppointmentsList(user.uid, 'today', theme),
          _buildAppointmentsList(user.uid, 'upcoming', theme),
          _buildAppointmentsList(user.uid, 'missed', theme),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(String userId, String filter, ThemeProvider theme) {
    Stream<List<Appointment>> appointmentsStream;

    switch (filter) {
      case 'today':
        appointmentsStream = AppointmentService.getTodaysAppointments(userId, 'doctor');
        break;
      case 'upcoming':
        appointmentsStream = AppointmentService.getUpcomingAppointments(userId, 'doctor');
        break;
      case 'missed':
        appointmentsStream = AppointmentService.getMissedAppointments(userId, 'doctor');
        break;
      case 'history':
        appointmentsStream = AppointmentService.getAllAppointments(userId, 'doctor');
        break;
      default:
        appointmentsStream = AppointmentService.getDoctorAppointments(userId);
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
            child: Text(
              'Error loading appointments: ${snapshot.error}',
              style: TextStyle(color: theme.textColor),
            ),
          );
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return _buildEmptyState(filter, theme);
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

  Widget _buildEmptyState(String filter, ThemeProvider theme) {
    String message;
    IconData icon;

    switch (filter) {
      case 'today':
        message = 'No appointments scheduled for today';
        icon = Icons.today_rounded;
        break;
      case 'upcoming':
        message = 'No upcoming appointments';
        icon = Icons.schedule_rounded;
        break;
      default:
        message = 'No appointments found';
        icon = Icons.calendar_today_rounded;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.subtextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: theme.subtextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create a new appointment',
            style: TextStyle(
              fontSize: 14,
              color: theme.subtextColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.formattedTime,
                        style: TextStyle(
                          fontSize: 14,
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
                    borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 16),

            // Patient info
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: theme.subtextColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: AppointmentService.getDoctorInfo(appointment.patientId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Text(
                          'Patient: ${snapshot.data!['name']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                      return Text(
                        'Patient: Loading...',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.subtextColor,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Purpose
            if (appointment.purpose.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              children: [
                if (appointment.status == 'pending' && _shouldShowRescheduleActions(appointment)) ...[
                  Expanded(
                    child: _buildActionButton(
                      'Confirm',
                      Icons.check_rounded,
                      Colors.green,
                      () => _updateAppointmentStatus(appointment.id!, 'confirmed'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (appointment.status != 'completed' && appointment.status != 'canceled') ...[
                  Expanded(
                    child: _buildActionButton(
                      'Cancel',
                      Icons.close_rounded,
                      Colors.red,
                      () => _updateAppointmentStatus(appointment.id!, 'canceled'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (appointment.status == 'confirmed') ...[
                  Expanded(
                    child: _buildActionButton(
                      'Complete',
                      Icons.done_all_rounded,
                      Colors.blue,
                      () => _updateAppointmentStatus(appointment.id!, 'completed'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'Request Reschedule',
                      Icons.schedule_rounded,
                      Colors.orange,
                      () => _rescheduleAppointment(appointment),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await AppointmentService.updateAppointmentStatus(appointmentId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment $status successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rescheduleAppointment(Appointment appointment) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RescheduleAppointmentScreen(
          themeProvider: widget.themeProvider,
          appointment: appointment,
        ),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reschedule request sent! Patient will need to confirm.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Helper method to determine if the current user should see reschedule actions
  bool _shouldShowRescheduleActions(Appointment appointment) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    
    // If no reschedule request was made, show actions to everyone (fallback)
    if (appointment.rescheduleRequestedBy == null) return true;
    
    // Show actions only to the user who didn't request the reschedule
    return appointment.rescheduleRequestedBy != currentUser.uid;
  }
}
