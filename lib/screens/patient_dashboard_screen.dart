import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/services/user_service.dart';

class PatientDashboardScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const PatientDashboardScreen({super.key, required this.themeProvider});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    // Load user profile data from UserService
    setState(() {
      _userProfile = UserService.getUserProfile();
      _initializeControllers();
      _isLoading = false;
    });
  }

  void _initializeControllers() {
    if (_userProfile != null) {
      _controllers = {
        'name': TextEditingController(text: _userProfile!['name'] ?? ''),
        'patientId': TextEditingController(text: _userProfile!['patientId'] ?? ''),
        'age': TextEditingController(text: _userProfile!['age']?.toString() ?? ''),
        'gender': TextEditingController(text: _userProfile!['gender'] ?? ''),
        'contactNumber': TextEditingController(text: _userProfile!['contactNumber'] ?? ''),
        'email': TextEditingController(text: _userProfile!['email'] ?? ''),
        'diagnosis': TextEditingController(text: _userProfile!['diagnosis'] ?? ''),
        'medications': TextEditingController(text: _userProfile!['medications'] ?? ''),
        'assignedDoctor': TextEditingController(text: _userProfile!['assignedDoctor'] ?? ''),
        'therapyStartDate': TextEditingController(text: _userProfile!['therapyStartDate'] ?? ''),
      };
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Profile Settings',
          style: TextStyle(
            color: theme.primaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.save : Icons.edit,
              color: theme.primaryColor,
            ),
            onPressed: _isEditing ? _saveChanges : _toggleEdit,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.primaryColor,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Welcome Message
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello! Welcome to your dashboard.',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.subtextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: theme.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: theme.subtextColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userProfile?['name'] ?? 'Surname, First Name',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userProfile?['patientId'] ?? '001-2345-678',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Personal Information
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildEditableInfoRow('Name', 'name'),
                    _buildDivider(false),
                    _buildEditableInfoRow('Age', 'age'),
                    _buildDivider(false),
                    _buildEditableInfoRow('Gender', 'gender'),
                    _buildDivider(false),
                    _buildEditableInfoRow('Contact No.', 'contactNumber'),
                    _buildDivider(false),
                    _buildEditableInfoRow('Email', 'email'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Medical Information
              Text(
                'Medical Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildEditableInfoRow('Disability / Diagnosis', 'diagnosis'),
                    _buildDivider(false),
                    _buildEditableInfoRow('Medications', 'medications'),
                    _buildDivider(false),
                    _buildEditableInfoRow('Assigned Doctor', 'assignedDoctor'),
                    _buildDivider(false),
                    _buildEditableInfoRow('Therapy Start Date', 'therapyStartDate'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showChangePasswordDialog();
                      },
                      icon: Icon(Icons.lock, color: theme.primaryColor),
                      label: Text('Change Password', style: TextStyle(color: theme.primaryColor)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: theme.primaryColor,
                          width: 1.5,
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
    );
  }

  Widget _buildEditableInfoRow(String label, String fieldKey) {
    final theme = widget.themeProvider;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ),
          Expanded(
            child: _isEditing
                ? TextField(
                    controller: _controllers[fieldKey],
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textColor,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.primaryColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  )
                : Text(
                    _controllers[fieldKey]?.text ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.subtextColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = true;
    });
  }

  void _saveChanges() async {
    setState(() {
      _isEditing = false;
    });
    
    // Update UserService with all field changes
    await UserService.updateUserProfile({
      'name': _controllers['name']?.text ?? '',
      'patientId': _controllers['patientId']?.text ?? '',
      'age': int.tryParse(_controllers['age']?.text ?? '') ?? 25,
      'gender': _controllers['gender']?.text ?? '',
      'contactNumber': _controllers['contactNumber']?.text ?? '',
      'email': _controllers['email']?.text ?? '',
      'diagnosis': _controllers['diagnosis']?.text ?? '',
      'medications': _controllers['medications']?.text ?? '',
      'assignedDoctor': _controllers['assignedDoctor']?.text ?? '',
      'therapyStartDate': _controllers['therapyStartDate']?.text ?? '',
    });
    
    // Update local profile state
    if (_userProfile != null) {
      _userProfile!['name'] = _controllers['name']?.text ?? '';
      _userProfile!['patientId'] = _controllers['patientId']?.text ?? '';
      _userProfile!['age'] = int.tryParse(_controllers['age']?.text ?? '') ?? 25;
      _userProfile!['gender'] = _controllers['gender']?.text ?? '';
      _userProfile!['contactNumber'] = _controllers['contactNumber']?.text ?? '';
      _userProfile!['email'] = _controllers['email']?.text ?? '';
      _userProfile!['diagnosis'] = _controllers['diagnosis']?.text ?? '';
      _userProfile!['medications'] = _controllers['medications']?.text ?? '';
      _userProfile!['assignedDoctor'] = _controllers['assignedDoctor']?.text ?? '';
      _userProfile!['therapyStartDate'] = _controllers['therapyStartDate']?.text ?? '';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final currentPassword = currentPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();
                
                if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('New passwords do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password must be at least 6 characters'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password changed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Change Password'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDivider(bool isDark) {
    final theme = widget.themeProvider;
    return Divider(
      color: theme.cardColor.withOpacity(0.2),
      height: 1,
    );
  }
}