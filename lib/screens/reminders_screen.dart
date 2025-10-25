import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/widgets/action_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import 'reschedule_appointment_screen.dart';

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
  String _userRole = 'patient';
  StreamSubscription<List<Appointment>>? _appointmentsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserRole();
    _loadReminders();
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


  Future<void> _loadReminders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .orderBy('scheduledTime', descending: false)
            .get();

        final reminders = snap.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? '',
            'schedule': data['schedule'] ?? '',
            'time': data['time'] ?? '',
            'isCompleted': data['isCompleted'] ?? false,
            'priority': data['priority'] ?? 'Medium',
            'source': data['source'] ?? 'user',
            'createdAt': data['createdAt'],
            'scheduledTime': data['scheduledTime'],
          };
        }).toList();

        // Sort by scheduled time (earliest first)
        reminders.sort((a, b) {
          final timeA = a['scheduledTime'] as Timestamp?;
          final timeB = b['scheduledTime'] as Timestamp?;
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;
          return timeA.compareTo(timeB);
        });

        setState(() {
          _reminders = reminders;
          _selectedReminders = List<bool>.filled(_reminders.length, false);
        });
      }
    } catch (e) {
      print('Error loading reminders: $e');
      // Show empty state if no reminders are found
      setState(() {
        _reminders = [];
        _selectedReminders = [];
      });
    }
  }

  Future<void> _createTodaysSessionReminder() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Check if today's session reminder already exists
        final existingReminder = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .where('title', isEqualTo: "Today's Session")
            .where('source', isEqualTo: 'system')
            .get();

        if (existingReminder.docs.isEmpty) {
          // Create today's session reminder
          final now = DateTime.now();
          final scheduledTime = DateTime(now.year, now.month, now.day, 8, 0); // 8:00 AM today
          
          final reminderData = {
            'title': "Today's Session",
            'schedule': 'Complete your assigned exercises',
            'time': '8:00 AM',
            'isCompleted': false,
            'priority': 'High',
            'source': 'system',
            'createdAt': FieldValue.serverTimestamp(),
            'scheduledTime': Timestamp.fromDate(scheduledTime),
          };

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('reminders')
              .add(reminderData);

          // Reload reminders to show the new one
          await _loadReminders();
        }
      }
    } catch (e) {
      print('Error creating today\'s session reminder: $e');
    }
  }

  Future<void> _addCustomReminder(String title, String schedule, String priority) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final reminderData = {
          'title': title,
          'schedule': schedule,
          'time': schedule,
          'isCompleted': false,
          'priority': priority,
          'source': 'custom',
          'createdAt': FieldValue.serverTimestamp(),
          'scheduledTime': FieldValue.serverTimestamp(),
        };

        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .add(reminderData);

        // Add to local state
        final newReminder = {
          'id': docRef.id,
          'title': title,
          'schedule': schedule,
          'time': schedule,
          'isCompleted': false,
          'priority': priority,
          'source': 'custom',
          'createdAt': DateTime.now(),
        };

        setState(() {
          _reminders = List<Map<String, Object?>>.from(_reminders);
          _selectedReminders = List<bool>.from(_selectedReminders);
          _reminders.insert(0, Map<String, Object?>.from(newReminder));
          _selectedReminders.insert(0, false);
        });

        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom reminder added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add reminder. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleReminder(int index) async {
    final isCompleted = _reminders[index]['isCompleted'] as bool? ?? false;
    if (isCompleted) return;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final reminderId = _reminders[index]['id'] as String;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(reminderId)
            .update({'isCompleted': !isCompleted});
        
        setState(() {
          _reminders[index]['isCompleted'] = !isCompleted;
        });
      }
    } catch (e) {
      print('Error updating reminder: $e');
    }
  }

  void _markAsComplete() {
    final selectedCount = _selectedReminders.where((s) => s).length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select reminders to mark as complete'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      for (int i = 0; i < _reminders.length; i++) {
        if (_selectedReminders[i]) {
          _reminders[i]['isCompleted'] = true;
          _selectedReminders[i] = false;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$selectedCount reminder(s) marked as complete'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _snoozeReminders() {
    final selectedCount = _selectedReminders.where((s) => s).length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select reminders to snooze'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$selectedCount reminder(s) snoozed for 1 hour'),
        backgroundColor: Colors.blue,
      ),
    );

    setState(() {
      _selectedReminders = List<bool>.filled(_reminders.length, false);
    });
  }

  void _showReminderMenu(int index) {
    final reminder = _reminders[index];
    final source = reminder['source'] as String? ?? 'user';

    // Only show menu for custom reminders
    if (source != 'custom') return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: widget.themeProvider.cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.themeProvider.subtextColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit, color: widget.themeProvider.primaryColor),
                title: Text(
                  'Edit Reminder',
                  style: TextStyle(color: widget.themeProvider.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editReminder(index);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Delete Reminder',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteReminder(index);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _editReminder(int index) {
    final reminder = _reminders[index];
    final title = reminder['title'] as String? ?? '';
    final schedule = reminder['schedule'] as String? ?? '';
    final priority = reminder['priority'] as String? ?? 'Low';

    // Parse schedule to extract date and time if possible
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String selectedRepeat = 'Once';

    // Simple parsing - this could be improved
    if (schedule.contains(' at ')) {
      final parts = schedule.split(' at ');
      if (parts.length == 2) {
        final datePart = parts[0];
        final timePart = parts[1];

        // Try to parse date
        if (datePart.contains('/')) {
          final dateParts = datePart.split('/');
          if (dateParts.length == 3) {
            try {
              selectedDate = DateTime(
                int.parse(dateParts[2]),
                int.parse(dateParts[1]),
                int.parse(dateParts[0]),
              );
            } catch (e) {
              // Ignore parsing errors
            }
          }
        }

        // Try to parse time
        if (timePart.contains(':')) {
          final timeParts = timePart.split(':');
          if (timeParts.length == 2) {
            try {
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1].split(' ')[0]);
              selectedTime = TimeOfDay(hour: hour, minute: minute);
            } catch (e) {
              // Ignore parsing errors
            }
          }
        }
      }
    } else if (schedule.contains('Daily') || schedule.contains('Weekly') || schedule.contains('Monthly')) {
      if (schedule.contains('Daily')) selectedRepeat = 'Daily';
      else if (schedule.contains('Weekly')) selectedRepeat = 'Weekly';
      else if (schedule.contains('Monthly')) selectedRepeat = 'Monthly';

      // Extract time from repeat schedule
      final timeMatch = RegExp(r'at (\d{1,2}:\d{2})').firstMatch(schedule);
      if (timeMatch != null) {
        final timeStr = timeMatch.group(1)!;
        final timeParts = timeStr.split(':');
        try {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          selectedTime = TimeOfDay(hour: hour, minute: minute);
        } catch (e) {
          // Ignore parsing errors
        }
      }
    }

    final titleController = TextEditingController(text: title);
    String selectedPriority = priority;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: widget.themeProvider.cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.themeProvider.subtextColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Reminder',
                            style: TextStyle(
                              color: widget.themeProvider.textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Title Field
                          TextField(
                            controller: titleController,
                            style: TextStyle(color: widget.themeProvider.textColor),
                            decoration: InputDecoration(
                              labelText: 'Reminder Title',
                              labelStyle: TextStyle(color: widget.themeProvider.subtextColor),
                              prefixIcon: Icon(Icons.title, color: widget.themeProvider.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: widget.themeProvider.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: widget.themeProvider.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: widget.themeProvider.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Date Picker
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: widget.themeProvider.primaryColor,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setState(() {
                                  selectedDate = date;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: widget.themeProvider.primaryColor.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: widget.themeProvider.primaryColor),
                                  const SizedBox(width: 12),
                                  Text(
                                    selectedDate == null
                                        ? 'Select Date'
                                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                    style: TextStyle(
                                      color: widget.themeProvider.textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Time Picker
                          InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedTime ?? TimeOfDay.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: widget.themeProvider.primaryColor,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (time != null) {
                                setState(() {
                                  selectedTime = time;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: widget.themeProvider.primaryColor.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, color: widget.themeProvider.primaryColor),
                                  const SizedBox(width: 12),
                                  Text(
                                    selectedTime == null
                                        ? 'Select Time'
                                        : selectedTime!.format(context),
                                    style: TextStyle(
                                      color: widget.themeProvider.textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Repeat Options
                          Text(
                            'Repeat',
                            style: TextStyle(
                              color: widget.themeProvider.subtextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ['Once', 'Daily', 'Weekly', 'Monthly'].map((repeat) {
                              return ChoiceChip(
                                label: Text(repeat),
                                selected: selectedRepeat == repeat,
                                onSelected: (selected) {
                                  setState(() {
                                    selectedRepeat = repeat;
                                  });
                                },
                                selectedColor: widget.themeProvider.primaryColor,
                                labelStyle: TextStyle(
                                  color: selectedRepeat == repeat
                                      ? Colors.white
                                      : widget.themeProvider.textColor,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Priority Selection
                          Text(
                            'Priority',
                            style: TextStyle(
                              color: widget.themeProvider.subtextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ['Low', 'Medium', 'High'].map((priority) {
                              final color = _getPriorityColor(priority);
                              return ChoiceChip(
                                label: Text(priority),
                                selected: selectedPriority == priority,
                                onSelected: (selected) {
                                  setState(() {
                                    selectedPriority = priority;
                                  });
                                },
                                selectedColor: color,
                                labelStyle: TextStyle(
                                  color: selectedPriority == priority
                                      ? Colors.white
                                      : widget.themeProvider.textColor,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: widget.themeProvider.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: widget.themeProvider.subtextColor,
                              side: BorderSide(color: widget.themeProvider.subtextColor),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (titleController.text.isEmpty ||
                                        selectedDate == null ||
                                        selectedTime == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please fill all fields'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      isLoading = true;
                                    });

                                    // Format the schedule string
                                    String schedule = '';
                                    if (selectedRepeat == 'Once') {
                                      schedule = '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} at ${selectedTime!.format(context)}';
                                    } else {
                                      schedule = '$selectedRepeat at ${selectedTime!.format(context)}';
                                    }

                                    _updateReminder(index, titleController.text, schedule, selectedPriority);

                                    Navigator.pop(context);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.themeProvider.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Update Reminder'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateReminder(int index, String title, String schedule, String priority) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final reminderId = _reminders[index]['id'] as String;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(reminderId)
            .update({
              'title': title,
              'schedule': schedule,
              'time': schedule,
              'priority': priority,
            });

        // Update local state
        setState(() {
          _reminders[index]['title'] = title;
          _reminders[index]['schedule'] = schedule;
          _reminders[index]['time'] = schedule;
          _reminders[index]['priority'] = priority;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update reminder. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteReminder(int index) {
    final reminder = _reminders[index];
    final title = reminder['title'] as String? ?? 'this reminder';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.themeProvider.cardColor,
          title: Text(
            'Delete Reminder',
            style: TextStyle(color: widget.themeProvider.textColor),
          ),
          content: Text(
            'Are you sure you want to delete "$title"?',
            style: TextStyle(color: widget.themeProvider.subtextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: widget.themeProvider.subtextColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _confirmDeleteReminder(index);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteReminder(int index) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final reminderId = _reminders[index]['id'] as String;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .doc(reminderId)
            .delete();

        // Update local state
        setState(() {
          _reminders.removeAt(index);
          _selectedReminders.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete reminder. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddCustomReminderDialog() {
    final titleController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String selectedPriority = 'Low';
    String selectedRepeat = 'Once';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: widget.themeProvider.cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.themeProvider.subtextColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create New Reminder',
                            style: TextStyle(
                              color: widget.themeProvider.textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Title Field with icon
                          TextField(
                            controller: titleController,
                            style: TextStyle(color: widget.themeProvider.textColor),
                            decoration: InputDecoration(
                              labelText: 'Reminder Title',
                              labelStyle: TextStyle(color: widget.themeProvider.subtextColor),
                              prefixIcon: Icon(Icons.title, color: widget.themeProvider.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: widget.themeProvider.primaryColor.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: widget.themeProvider.primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: widget.themeProvider.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Date Picker
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: widget.themeProvider.primaryColor,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setState(() {
                                  selectedDate = date;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: widget.themeProvider.primaryColor.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: widget.themeProvider.primaryColor),
                                  const SizedBox(width: 12),
                                  Text(
                                    selectedDate == null
                                        ? 'Select Date'
                                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                    style: TextStyle(
                                      color: widget.themeProvider.textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Time Picker
                          InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: widget.themeProvider.primaryColor,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (time != null) {
                                setState(() {
                                  selectedTime = time;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: widget.themeProvider.primaryColor.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, color: widget.themeProvider.primaryColor),
                                  const SizedBox(width: 12),
                                  Text(
                                    selectedTime == null
                                        ? 'Select Time'
                                        : selectedTime!.format(context),
                                    style: TextStyle(
                                      color: widget.themeProvider.textColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Repeat Options
                          Text(
                            'Repeat',
                            style: TextStyle(
                              color: widget.themeProvider.subtextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ['Once', 'Daily', 'Weekly', 'Monthly'].map((repeat) {
                              return ChoiceChip(
                                label: Text(repeat),
                                selected: selectedRepeat == repeat,
                                onSelected: (selected) {
                                  setState(() {
                                    selectedRepeat = repeat;
                                  });
                                },
                                selectedColor: widget.themeProvider.primaryColor,
                                labelStyle: TextStyle(
                                  color: selectedRepeat == repeat
                                      ? Colors.white
                                      : widget.themeProvider.textColor,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          
                          // Priority Selection
                          Text(
                            'Priority',
                            style: TextStyle(
                              color: widget.themeProvider.subtextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ['Low', 'Medium', 'High'].map((priority) {
                              final color = _getPriorityColor(priority);
                              return ChoiceChip(
                                label: Text(priority),
                                selected: selectedPriority == priority,
                                onSelected: (selected) {
                                  setState(() {
                                    selectedPriority = priority;
                                  });
                                },
                                selectedColor: color,
                                labelStyle: TextStyle(
                                  color: selectedPriority == priority
                                      ? Colors.white
                                      : widget.themeProvider.textColor,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom Action Buttons
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: widget.themeProvider.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: widget.themeProvider.subtextColor,
                              side: BorderSide(color: widget.themeProvider.subtextColor),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (titleController.text.isEmpty ||
                                        selectedDate == null ||
                                        selectedTime == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please fill all fields'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      isLoading = true;
                                    });

                                    // Format the schedule string
                                    String schedule = '';
                                    if (selectedRepeat == 'Once') {
                                      schedule = '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} at ${selectedTime!.format(context)}';
                                    } else {
                                      schedule = '$selectedRepeat at ${selectedTime!.format(context)}';
                                    }

                                    _addCustomReminder(
                                      titleController.text,
                                      schedule,
                                      selectedPriority,
                                    );

                                    Navigator.pop(context);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.themeProvider.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Create Reminder'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;

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
          'Reminders & Appointments',
          style: TextStyle(
            color: theme.primaryColor,
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
          _buildUpcomingAppointmentsTab(theme),
        ],
      ),
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
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.notifications_active, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 16),
                Text('Your Reminders',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textColor),
                ),
                const SizedBox(height: 8),
                Text('Stay on track with your physical therapy',
                  style: TextStyle(fontSize: 14, color: theme.subtextColor),
                ),
              ],
            ),
          ),

          Expanded(
            child: _reminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off, size: 64, color: theme.subtextColor),
                        const SizedBox(height: 16),
                        Text('No reminders assigned yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
                        ),
                        const SizedBox(height: 8),
                        Text('Your doctor will assign exercises, appointments,\nand medication reminders here',
                          style: TextStyle(fontSize: 14, color: theme.subtextColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddCustomReminderDialog,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Create Custom Reminder', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
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
                      final title = reminder['title'] as String? ?? '';
                      final schedule = reminder['schedule'] as String? ?? '';
                      final priority = reminder['priority'] as String? ?? '';
                      final isCompleted = reminder['isCompleted'] as bool? ?? false;
                      final isSelected = _selectedReminders[index];

                      final source = reminder['source'] as String? ?? 'user';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleReminder(index),
                            onLongPress: () => _showReminderMenu(index),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isSelected
                                    ? theme.primaryColor.withOpacity(0.05)
                                    : theme.cardColor,
                                border: Border.all(
                                  color: isSelected
                                      ? theme.primaryColor
                                      : theme.subtextColor.withOpacity(0.1),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Compact icon
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(priority).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      source == 'system' 
                                          ? Icons.fitness_center
                                          : priority.toLowerCase() == 'high'
                                              ? Icons.priority_high
                                              : priority.toLowerCase() == 'medium'
                                                  ? Icons.remove
                                                  : Icons.keyboard_arrow_down,
                                      color: _getPriorityColor(priority),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isCompleted
                                                      ? theme.subtextColor
                                                      : theme.textColor,
                                                  decoration: isCompleted
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Priority badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getPriorityColor(priority).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                priority,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: _getPriorityColor(priority),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              size: 12,
                                              color: theme.subtextColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                schedule,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: theme.subtextColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Completion checkbox
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.primaryColor
                                            : theme.subtextColor.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      color: isSelected
                                          ? theme.primaryColor
                                          : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 12,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // --- Bottom Buttons ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          onPressed: _markAsComplete,
                          text: 'Complete',
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                          themeProvider: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ActionButton(
                          onPressed: _snoozeReminders,
                          text: 'Snooze',
                          icon: Icons.snooze,
                          color: Colors.orange,
                          themeProvider: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 56,
                        width: 56,
                        child: Material(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: _showAddCustomReminderDialog,
                            borderRadius: BorderRadius.circular(16),
                            child: const Center(
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointmentsTab(ThemeProvider theme) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: AppBar(
          backgroundColor: theme.backgroundColor,
          elevation: 0,
          automaticallyImplyLeading: false,
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
    );
  }

  Widget _buildMissedAppointmentsContent(ThemeProvider theme) {
    return SafeArea(
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
    );
  }

  Widget _buildAppointmentHistoryContent(ThemeProvider theme) {
    return SafeArea(
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
                    color: _getAppointmentStatusColor(appointment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 16),

            // Person info
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
                    future: _userRole == 'doctor' 
                        ? AppointmentService.getDoctorInfo(appointment.patientId)
                        : AppointmentService.getDoctorInfo(appointment.doctorId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Text(
                          '${_userRole == 'doctor' ? 'Patient' : 'Doctor'}: ${snapshot.data!['name']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                      return Text(
                        '${_userRole == 'doctor' ? 'Patient' : 'Doctor'}: Loading...',
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
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

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

            // Action buttons for upcoming appointments
            if (!isMissed && !showAllDetails) ...[
              const SizedBox(height: 16),
              if (appointment.status == 'confirmed') ...[
                // Regular confirmed appointment actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rescheduleAppointment(appointment),
                        icon: const Icon(Icons.schedule_rounded, size: 16),
                        label: const Text('Request Reschedule'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          foregroundColor: Colors.orange,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.orange.withOpacity(0.3)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsCompleted(appointment.id!),
                        icon: const Icon(Icons.done_all_rounded, size: 16),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          foregroundColor: Colors.blue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (appointment.status == 'pending') ...[
                // Pending reschedule request actions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Reschedule Request Pending',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _confirmReschedule(appointment.id!),
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text('Confirm'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.withOpacity(0.1),
                                foregroundColor: Colors.green,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.green.withOpacity(0.3)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _rejectReschedule(appointment.id!),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.1),
                                foregroundColor: Colors.red,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
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
      final confirmationMessage = _userRole == 'doctor' 
          ? 'Reschedule request sent! Patient will need to confirm.'
          : 'Reschedule request sent! Doctor will need to confirm.';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(confirmationMessage),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _markAsCompleted(String appointmentId) async {
    try {
      await AppointmentService.markAppointmentAsCompleted(appointmentId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment marked as completed!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark appointment as completed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmReschedule(String appointmentId) async {
    try {
      await AppointmentService.updateAppointmentStatus(appointmentId, 'confirmed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reschedule request confirmed!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm reschedule: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectReschedule(String appointmentId) async {
    try {
      await AppointmentService.updateAppointmentStatus(appointmentId, 'canceled');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reschedule request rejected!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject reschedule: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
