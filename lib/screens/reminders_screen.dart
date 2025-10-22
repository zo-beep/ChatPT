import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/widgets/action_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RemindersScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const RemindersScreen({super.key, required this.themeProvider});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Map<String, Object?>> _reminders = [];
  List<bool> _selectedReminders = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadReminders();
  }

  Future<void> _initializeNotifications() async {
    // Notifications removed
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('reminders') ?? [];

    List<Map<String, Object?>> loadedReminders = [];
    if (remindersJson.isEmpty) {
      // Load initial reminders if none saved
      loadedReminders = [
        {
          'id': 1,
          'title': 'Morning Exercise Routine',
          'schedule': 'Daily at 8:00 AM',
          'time': '8:00 AM',
          'isCompleted': false,
          'priority': 'High',
          'source': 'doctor',
        },
        {
          'id': 2,
          'title': 'Physical Therapy Session',
          'schedule': 'Monday, Wednesday, Friday at 2:00 PM',
          'time': '2:00 PM',
          'isCompleted': false,
          'priority': 'High',
          'source': 'doctor',
        },
        {
          'id': 3,
          'title': 'Medication Reminder',
          'schedule': 'Twice daily - 9:00 AM & 6:00 PM',
          'time': '9:00 AM',
          'isCompleted': false,
          'priority': 'Medium',
          'source': 'doctor',
        },
        {
          'id': 4,
          'title': 'Doctor Appointment',
          'schedule': 'Next Friday at 10:30 AM',
          'time': '10:30 AM',
          'isCompleted': false,
          'priority': 'High',
          'source': 'doctor',
        },
        {
          'id': 5,
          'title': 'Personal Water Break',
          'schedule': 'Every hour',
          'time': 'Every hour',
          'isCompleted': false,
          'priority': 'Low',
          'source': 'user',
        },
      ];
    } else {
      // Load from SharedPreferences
      loadedReminders = remindersJson.map((json) => jsonDecode(json) as Map<String, Object?>).toList();
    }

    setState(() {
      _reminders = List<Map<String, Object?>>.from(loadedReminders);
      _selectedReminders = List<bool>.generate(_reminders.length, (_) => false);
    });


  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = _reminders.map((reminder) => jsonEncode(reminder)).toList();
    await prefs.setStringList('reminders', remindersJson);
  }

  Future<void> _addCustomReminder(String title, String schedule, String priority) async {
    final newReminder = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': title,
      'schedule': schedule,
      'time': schedule,
      'isCompleted': false,
      'priority': priority,
      'source': 'custom',
    };

    setState(() {
      _reminders = List<Map<String, Object?>>.from(_reminders);
      _selectedReminders = List<bool>.from(_selectedReminders);
      _reminders.insert(0, Map<String, Object?>.from(newReminder));
      _selectedReminders.insert(0, false);
    });

    // Save to SharedPreferences
    await _saveReminders();

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

  void _scheduleAllReminders() {
    // Notification scheduling removed
  }

  void _toggleReminder(int index) {
    final isCompleted = _reminders[index]['isCompleted'] as bool? ?? false;
    if (isCompleted) return;
    setState(() {
      _selectedReminders[index] = !_selectedReminders[index];
    });
  }

  Future<void> _markAsComplete() async {
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

    // Save updated reminders to SharedPreferences
    await _saveReminders();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$selectedCount reminder(s) marked as complete'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _editReminder(int index) async {
    final reminder = _reminders[index];
    final titleController = TextEditingController(text: reminder['title'] as String? ?? '');
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String selectedPriority = reminder['priority'] as String? ?? 'Low';
    String selectedRepeat = 'Once'; // Default, will be parsed from schedule
    bool isLoading = false;

    // Parse existing schedule to pre-fill date/time/repeat
    final schedule = reminder['schedule'] as String? ?? '';
    if (schedule.contains(' at ')) {
      final parts = schedule.split(' at ');
      if (parts.length == 2) {
        selectedRepeat = parts[0];
        final timeStr = parts[1];
        // Parse time (simplified)
        final timeParts = timeStr.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1].split(' ')[0]) ?? 0;
          final period = timeParts[1].split(' ')[1];
          selectedTime = TimeOfDay(hour: period == 'PM' && hour != 12 ? hour + 12 : hour, minute: minute);
        }
      }
    }

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
                                : () async {
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

                                    // Update reminder
                                    setState(() {
                                      _reminders[index] = {
                                        ...reminder,
                                        'title': titleController.text,
                                        'schedule': schedule,
                                        'time': schedule,
                                        'priority': selectedPriority,
                                      };
                                    });

                                    // Save to SharedPreferences
                                    await _saveReminders();

                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Reminder updated successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
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

  Future<void> _removeReminder(int index) async {
    setState(() {
      _reminders.removeAt(index);
      _selectedReminders.removeAt(index);
    });

    // Save to SharedPreferences
    await _saveReminders();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder removed successfully!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showReminderOptions(int index) {
    final reminder = _reminders[index];
    final isCompleted = reminder['isCompleted'] as bool? ?? false;

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

              // Options
              ListTile(
                leading: Icon(
                  Icons.edit,
                  color: widget.themeProvider.primaryColor,
                ),
                title: Text(
                  'Edit Reminder',
                  style: TextStyle(
                    color: widget.themeProvider.textColor,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _editReminder(index);
                },
              ),

              if (!isCompleted) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  title: Text(
                    'Mark as Complete',
                    style: TextStyle(
                      color: widget.themeProvider.textColor,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _reminders[index]['isCompleted'] = true;
                    });
                    _saveReminders();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reminder marked as complete'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],

              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                title: Text(
                  'Delete Reminder',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: widget.themeProvider.cardColor,
                        title: Text(
                          'Delete Reminder',
                          style: TextStyle(
                            color: widget.themeProvider.textColor,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to delete this reminder?',
                          style: TextStyle(
                            color: widget.themeProvider.subtextColor,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: widget.themeProvider.subtextColor,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // close dialog
                              Navigator.pop(context); // close bottom sheet
                              _removeReminder(index);
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
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
        'Reminders',
        style: TextStyle(
          color: theme.primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    ),
    body: SafeArea(
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
                Text(
                  'Your Reminders',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stay on track with your physical therapy',
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
                        Text(
                          'No reminders assigned yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your doctor will assign exercises, appointments,\nand medication reminders here',
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

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleReminder(index),
                            onLongPress: () => _showReminderOptions(index),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: isSelected ? theme.primaryColor.withOpacity(0.1) : theme.cardColor,
                                border: Border.all(
                                  color: isSelected ? theme.primaryColor : theme.primaryColor.withOpacity(0.1),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      // Category Icon with Background
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(priority).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          priority.toLowerCase() == 'high'
                                              ? Icons.priority_high
                                              : priority.toLowerCase() == 'medium'
                                                  ? Icons.watch_later
                                                  : Icons.low_priority,
                                          color: _getPriorityColor(priority),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isCompleted ? theme.subtextColor : theme.textColor,
                                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.schedule,
                                                  size: 14,
                                                  color: theme.subtextColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  schedule,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: theme.subtextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Checkbox with custom design
                                      InkWell(
                                        onTap: isCompleted ? null : () => _toggleReminder(index),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isSelected
                                                  ? theme.primaryColor
                                                  : theme.subtextColor.withOpacity(0.3),
                                              width: 2,
                                            ),
                                            color: isSelected ? theme.primaryColor : Colors.transparent,
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isCompleted) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Completed',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                          icon: Icons.check_circle_outline,
                          label: 'Complete',
                          color: Colors.green,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ActionButton(
                          onPressed: _snoozeReminders,
                          icon: Icons.snooze,
                          label: 'Snooze',
                          color: Colors.orange,
                          theme: theme,
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
    ),
  );
}
}