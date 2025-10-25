import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/widgets/action_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/appointment.dart';
import '../services/appointment_service.dart';

class RemindersScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const RemindersScreen({super.key, required this.themeProvider});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> with TickerProviderStateMixin {
  List<Map<String, Object?>> _reminders = [];
  List<bool> _selectedReminders = [];
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  List<Appointment> _appointments = [];
  String _userRole = 'patient';
  StreamSubscription<List<Appointment>>? _appointmentsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserRole();
    _loadReminders();
    _loadAppointments();
    // Mark past appointments as missed when the screen loads
    AppointmentService.markPastAppointmentsAsMissed();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _appointmentsSubscription?.cancel();
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

  Future<void> _loadAppointments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Loading appointments for user: ${user.uid}, role: $_userRole');
        final appointmentsStream = AppointmentService.getUpcomingAppointments(user.uid, _userRole);
        _appointmentsSubscription = appointmentsStream.listen(
          (appointments) {
            print('Received ${appointments.length} appointments');
            if (mounted) {
              setState(() {
                _appointments = appointments;
              });
            }
          },
          onError: (error) {
            print('Error in appointments stream: $error');
          },
        );
      }
    } catch (e) {
      print('Error loading appointments: $e');
    }
  }

  Future<void> _loadReminders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Loading reminders for user: ${user.uid}');
        final remindersSnapshot = await FirebaseFirestore.instance
            .collection('reminders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();

        List<Map<String, Object?>> reminders = [];
        for (var doc in remindersSnapshot.docs) {
          reminders.add({
            'id': doc.id,
            ...doc.data(),
          });
        }

        setState(() {
          _reminders = reminders;
          _selectedReminders = List.filled(reminders.length, false);
        });
      }
    } catch (e) {
      print('Error loading reminders: $e');
    }
  }

  Future<void> _deleteSelectedReminders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      List<String> reminderIdsToDelete = [];
      for (int i = 0; i < _selectedReminders.length; i++) {
        if (_selectedReminders[i]) {
          reminderIdsToDelete.add(_reminders[i]['id'] as String);
        }
      }

      if (reminderIdsToDelete.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select reminders to delete'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Delete reminders from Firestore
      for (String reminderId in reminderIdsToDelete) {
        await FirebaseFirestore.instance
            .collection('reminders')
            .doc(reminderId)
            .delete();
      }

      // Refresh the reminders list
      await _loadReminders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${reminderIdsToDelete.length} reminder(s) deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting reminders: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting reminders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addReminder() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() {
                              selectedDate = date;
                            });
                          }
                        },
                        child: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedTime = time;
                            });
                          }
                        },
                        child: Text('${selectedTime.format(context)}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final reminderDateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );

          await FirebaseFirestore.instance.collection('reminders').add({
            'userId': user.uid,
            'title': titleController.text.trim(),
            'description': descriptionController.text.trim(),
            'reminderDateTime': Timestamp.fromDate(reminderDateTime),
            'createdAt': FieldValue.serverTimestamp(),
            'isCompleted': false,
          });

          await _loadReminders();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reminder added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        print('Error adding reminder: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding reminder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeProvider,
      builder: (context, child) {
        final theme = widget.themeProvider;
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
              'Reminders',
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
              tabs: const [
                Tab(text: 'Reminders'),
                Tab(text: 'Appointments'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildRemindersTab(theme),
              _buildAppointmentsTab(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRemindersTab(ThemeProvider theme) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.notifications_rounded,
                    size: 30,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Personal Reminders',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your personal reminders and tasks',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.subtextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (_reminders.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      text: 'Add Reminder',
                      onPressed: _addReminder,
                      themeProvider: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionButton(
                      text: 'Delete Selected',
                      onPressed: _deleteSelectedReminders,
                      themeProvider: theme,
                      isSecondary: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Expanded(
            child: _reminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 64,
                          color: theme.subtextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No reminders yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first reminder to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.subtextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ActionButton(
                          text: 'Add Reminder',
                          onPressed: _addReminder,
                          themeProvider: theme,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];
                      return _buildReminderCard(reminder, index, theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab(ThemeProvider theme) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: AppBar(
          backgroundColor: theme.backgroundColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Appointments',
            style: TextStyle(
              color: theme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: theme.primaryColor,
            labelColor: theme.primaryColor,
            unselectedLabelColor: theme.subtextColor,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Missed'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUpcomingAppointmentsContent(theme),
            _buildMissedAppointmentsContent(theme),
            _buildAppointmentHistoryContent(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointmentsContent(ThemeProvider theme) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.event_rounded,
                    size: 30,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Upcoming Appointments',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your scheduled appointments',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.subtextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Appointment>>(
              stream: AppointmentService.getUpcomingAppointments(
                FirebaseAuth.instance.currentUser?.uid ?? '',
                _userRole,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.primaryColor,
                    ),
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
                      ],
                    ),
                  );
                }

                final upcomingAppointments = snapshot.data ?? [];

                if (upcomingAppointments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 64,
                          color: theme.subtextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No upcoming appointments',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your upcoming appointments will appear here.',
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: upcomingAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = upcomingAppointments[index];
                    return _buildAppointmentCard(appointment, theme);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissedAppointmentsContent(ThemeProvider theme) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.event_busy_rounded,
                    size: 30,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Missed Appointments',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Appointments that were not attended',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.subtextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Appointment>>(
              stream: AppointmentService.getMissedAppointments(
                FirebaseAuth.instance.currentUser?.uid ?? '',
                _userRole,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.primaryColor,
                    ),
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
                          'Error loading missed appointments',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final missedAppointments = snapshot.data ?? [];

                if (missedAppointments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No missed appointments',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Great job! You haven\'t missed any appointments.',
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: missedAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = missedAppointments[index];
                    return _buildAppointmentCard(appointment, theme, isMissed: true);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentHistoryContent(ThemeProvider theme) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    size: 30,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Appointment History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete record of all your appointments',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.subtextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Appointment>>(
              stream: AppointmentService.getAllAppointments(
                FirebaseAuth.instance.currentUser?.uid ?? '',
                _userRole,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.primaryColor,
                    ),
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
                          'Error loading appointment history',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.textColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allAppointments = snapshot.data ?? [];

                if (allAppointments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note_rounded,
                          size: 64,
                          color: theme.subtextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No appointment history',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your appointment history will appear here.',
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: allAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = allAppointments[index];
                    return _buildAppointmentCard(appointment, theme, showAllDetails: true);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Map<String, Object?> reminder, int index, ThemeProvider theme) {
    final title = reminder['title'] as String? ?? 'Untitled';
    final description = reminder['description'] as String? ?? '';
    final reminderDateTime = (reminder['reminderDateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
    final isCompleted = reminder['isCompleted'] as bool? ?? false;

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
            Row(
              children: [
                Checkbox(
                  value: _selectedReminders[index],
                  onChanged: (value) {
                    setState(() {
                      _selectedReminders[index] = value ?? false;
                    });
                  },
                  activeColor: theme.primaryColor,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.subtextColor,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('reminders')
                          .doc(reminder['id'] as String)
                          .update({
                        'isCompleted': !isCompleted,
                      });
                      await _loadReminders();
                    } catch (e) {
                      print('Error updating reminder: $e');
                    }
                  },
                  icon: Icon(
                    isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isCompleted ? Colors.green : theme.subtextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: theme.subtextColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(reminderDateTime),
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

  Widget _buildAppointmentCard(Appointment appointment, ThemeProvider theme, {bool isMissed = false, bool showAllDetails = false}) {
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
                    color: _getAppointmentStatusColor(appointment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getAppointmentStatusColor(appointment.status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    appointment.statusDisplayText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getAppointmentStatusColor(appointment.status),
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateStr;
    if (appointmentDate.isAtSameMomentAs(today)) {
      dateStr = 'Today';
    } else if (appointmentDate.isAtSameMomentAs(today.add(Duration(days: 1)))) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }

  Color _getAppointmentStatusColor(String status) {
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
