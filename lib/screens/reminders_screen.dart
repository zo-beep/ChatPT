import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';

class RemindersScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const RemindersScreen({super.key, required this.themeProvider});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Map<String, dynamic>> _reminders = [];
  List<bool> _selectedReminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  void _loadReminders() {
    setState(() {
      _reminders = [
        {
          'id': 1,
          'title': 'Morning Exercise Routine',
          'schedule': 'Daily at 8:00 AM',
          'time': '8:00 AM',
          'isCompleted': false,
          'priority': 'High',
          'source': 'doctor', // doctor-assigned
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
          'source': 'user', // user-created
        },
      ];
      _selectedReminders = List.filled(_reminders.length, false);
    });
  }

  void _toggleReminder(int index) {
    // Don't allow toggling completed reminders
    if (_reminders[index]['isCompleted'] == true) {
      return;
    }
    
    setState(() {
      _selectedReminders[index] = !_selectedReminders[index];
    });
  }

  void _markAsComplete() {
    final selectedCount = _selectedReminders.where((selected) => selected).length;
    
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
    final selectedCount = _selectedReminders.where((selected) => selected).length;
    
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
      _selectedReminders = List.filled(_reminders.length, false);
    });
  }

  void _addCustomReminder(String title, String schedule, String priority) {
    setState(() {
      _reminders.add({
        'id': DateTime.now().millisecondsSinceEpoch, // Use timestamp as unique ID
        'title': title,
        'schedule': schedule,
        'time': schedule,
        'isCompleted': false,
        'priority': priority,
        'source': 'user',
      });
      _selectedReminders.add(false);
    });
  }

  void _showAddCustomReminderDialog() {
    final titleController = TextEditingController();
    final scheduleController = TextEditingController();
    String selectedPriority = 'Low';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Add Custom Reminder',
                style: TextStyle(
                  color: widget.themeProvider.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Reminder Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: scheduleController,
                    decoration: InputDecoration(
                      labelText: 'Schedule (e.g., Daily at 9:00 AM)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: ['Low', 'Medium', 'High'].map((String priority) {
                      return DropdownMenuItem<String>(
                        value: priority,
                        child: Text(priority),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedPriority = newValue!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: widget.themeProvider.subtextColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty && 
                        scheduleController.text.isNotEmpty) {
                      _addCustomReminder(
                        titleController.text,
                        scheduleController.text,
                        selectedPriority,
                      );
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Custom reminder added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeProvider.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
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
          icon: Icon(
            Icons.arrow_back,
            color: theme.primaryColor,
          ),
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
            // Header
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
                    child: Icon(
                      Icons.notifications_active,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Reminders',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stay on track with your physical therapy',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Reminders List
            Expanded(
              child: _reminders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 64,
                            color: theme.subtextColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reminders assigned yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your doctor will assign exercises, appointments,\nand medication reminders here',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.subtextColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showAddCustomReminderDialog,
                            icon: Icon(Icons.add, color: Colors.white),
                            label: Text(
                              'Create Custom Reminder',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _reminders.length,
                      itemBuilder: (context, index) {
                        final reminder = _reminders[index];
                        final isSelected = _selectedReminders[index];
                        final isCompleted = reminder['isCompleted'] as bool;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _toggleReminder(index),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected 
                                      ? theme.primaryColor.withOpacity(0.1)
                                      : theme.cardColor,
                                  border: isSelected 
                                      ? Border.all(color: theme.primaryColor, width: 2)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    // Checkbox
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: isCompleted ? null : (value) => _toggleReminder(index),
                                      activeColor: theme.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Reminder Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  reminder['title'],
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: isCompleted 
                                                        ? theme.subtextColor 
                                                        : theme.textColor,
                                                    decoration: isCompleted 
                                                        ? TextDecoration.lineThrough 
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                              // Show priority only if not completed
                                              if (!isCompleted)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getPriorityColor(reminder['priority']).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    reminder['priority'],
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: _getPriorityColor(reminder['priority']),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule,
                                                size: 16,
                                                color: theme.subtextColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                reminder['schedule'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: theme.subtextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Completion Status
                                    if (isCompleted)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Marked as Complete',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
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
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Add Reminder Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showAddCustomReminderDialog,
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text(
                        'Add Custom Reminder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _markAsComplete,
                          icon: Icon(Icons.check_circle, color: Colors.white),
                          label: Text(
                            'Mark as Complete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _snoozeReminders,
                          icon: Icon(Icons.snooze, color: Colors.white),
                          label: Text(
                            'Snooze',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
        ),
      ),
    );
  }
}
