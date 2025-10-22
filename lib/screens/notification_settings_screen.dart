import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const NotificationSettingsScreen({super.key, required this.themeProvider});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotificationsEnabled = true;
  bool _exerciseRemindersEnabled = true;
  bool _dailyRemindersEnabled = true;
  bool _weeklyRemindersEnabled = true;
  bool _progressUpdatesEnabled = true;
  String _reminderTime = '09:00';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotificationsEnabled = prefs.getBool('push_notifications_enabled') ?? true;
      _exerciseRemindersEnabled = prefs.getBool('exercise_reminders_enabled') ?? true;
      _dailyRemindersEnabled = prefs.getBool('daily_reminders_enabled') ?? true;
      _weeklyRemindersEnabled = prefs.getBool('weekly_reminders_enabled') ?? true;
      _progressUpdatesEnabled = prefs.getBool('progress_updates_enabled') ?? true;
      _reminderTime = prefs.getString('reminder_time') ?? '09:00';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', _pushNotificationsEnabled);
    await prefs.setBool('exercise_reminders_enabled', _exerciseRemindersEnabled);
    await prefs.setBool('daily_reminders_enabled', _dailyRemindersEnabled);
    await prefs.setBool('weekly_reminders_enabled', _weeklyRemindersEnabled);
    await prefs.setBool('progress_updates_enabled', _progressUpdatesEnabled);
    await prefs.setString('reminder_time', _reminderTime);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime(2024, 1, 1, int.parse(_reminderTime.split(':')[0]), int.parse(_reminderTime.split(':')[1])),
      ),
    );
    
    if (picked != null) {
      setState(() {
        _reminderTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.themeProvider.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.themeProvider.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Settings',
          style: TextStyle(color: widget.themeProvider.primaryColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main toggle
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: Text(
                  'Push Notifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.themeProvider.textColor,
                  ),
                ),
                subtitle: Text(
                  'Enable or disable all push notifications',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.themeProvider.subtextColor,
                  ),
                ),
                value: _pushNotificationsEnabled,
                onChanged: (value) async {
                  setState(() {
                    _pushNotificationsEnabled = value;
                    // Disable all other settings if main toggle is off
                    if (!value) {
                      _exerciseRemindersEnabled = false;
                      _dailyRemindersEnabled = false;
                      _weeklyRemindersEnabled = false;
                      _progressUpdatesEnabled = false;
                    }
                  });
                  await _saveSettings();
                },
                activeColor: widget.themeProvider.primaryColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notification types
            Text(
              'Notification Types',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.themeProvider.textColor,
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Exercise Reminders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: widget.themeProvider.textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Get reminded about your daily exercises',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.themeProvider.subtextColor,
                      ),
                    ),
                    value: _exerciseRemindersEnabled,
                    onChanged: _pushNotificationsEnabled ? (value) async {
                      setState(() {
                        _exerciseRemindersEnabled = value;
                      });
                      await _saveSettings();
                    } : null,
                    activeColor: widget.themeProvider.primaryColor,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      'Daily Reminders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: widget.themeProvider.textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Daily motivation and session reminders',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.themeProvider.subtextColor,
                      ),
                    ),
                    value: _dailyRemindersEnabled,
                    onChanged: _pushNotificationsEnabled ? (value) async {
                      setState(() {
                        _dailyRemindersEnabled = value;
                      });
                      await _saveSettings();
                    } : null,
                    activeColor: widget.themeProvider.primaryColor,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      'Weekly Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: widget.themeProvider.textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Weekly progress updates and achievements',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.themeProvider.subtextColor,
                      ),
                    ),
                    value: _weeklyRemindersEnabled,
                    onChanged: _pushNotificationsEnabled ? (value) async {
                      setState(() {
                        _weeklyRemindersEnabled = value;
                      });
                      await _saveSettings();
                    } : null,
                    activeColor: widget.themeProvider.primaryColor,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      'Progress Updates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: widget.themeProvider.textColor,
                      ),
                    ),
                    subtitle: Text(
                      'Updates about your therapy progress',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.themeProvider.subtextColor,
                      ),
                    ),
                    value: _progressUpdatesEnabled,
                    onChanged: _pushNotificationsEnabled ? (value) async {
                      setState(() {
                        _progressUpdatesEnabled = value;
                      });
                      await _saveSettings();
                    } : null,
                    activeColor: widget.themeProvider.primaryColor,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Reminder time
            Text(
              'Reminder Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.themeProvider.textColor,
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.access_time,
                  color: widget.themeProvider.primaryColor,
                ),
                title: Text(
                  'Daily Reminder Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.themeProvider.textColor,
                  ),
                ),
                subtitle: Text(
                  'Set the time for your daily reminders',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.themeProvider.subtextColor,
                  ),
                ),
                trailing: Text(
                  _reminderTime,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.themeProvider.primaryColor,
                  ),
                ),
                onTap: _pushNotificationsEnabled ? _selectTime : null,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test notification button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pushNotificationsEnabled ? () async {
                  // Show a test notification
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Test notification sent!'),
                      backgroundColor: widget.themeProvider.primaryColor,
                    ),
                  );
                } : null,
                icon: const Icon(Icons.notifications),
                label: const Text('Send Test Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeProvider.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info card
            Card(
              elevation: 1,
              color: widget.themeProvider.primaryColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: widget.themeProvider.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: widget.themeProvider.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notification settings are saved locally on your device. You can change them anytime.',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.themeProvider.textColor,
                        ),
                      ),
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

