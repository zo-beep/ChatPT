import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';

class PatientDashboardScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const PatientDashboardScreen({super.key, required this.themeProvider});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    // Load mock user profile data
    setState(() {
      _userProfile = {
        'name': 'Jane Doe',
        'patientId': '001-2345-678',
        'age': 25,
        'gender': 'Female',
        'contactNumber': '09123456789',
        'email': 'jane.doe@example.com',
        'diagnosis': 'Knee Pain',
        'medications': 'Glucosamine',
        'assignedDoctor': 'Dr. John Doe',
        'therapyStartDate': 'December 4, 2025',
      };
      _isLoading = false;
    });
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
          'Back',
          style: TextStyle(
            color: theme.primaryColor,
          ),
        ),
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
              // Header (gradient like MoreScreen)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text(
                      'ChatPT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'J',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                    _buildInfoRow('Name', _userProfile?['name'] ?? 'Surname, FirstName MiddleName', false),
                    _buildDivider(false),
                    _buildInfoRow('Age', '${_userProfile?['age'] ?? 25}', false),
                    _buildDivider(false),
                    _buildInfoRow('Gender', _userProfile?['gender'] ?? 'Male', false),
                    _buildDivider(false),
                    _buildInfoRow('Contact No.', _userProfile?['contactNumber'] ?? '09123456789', false),
                    _buildDivider(false),
                    _buildInfoRow('Email', _userProfile?['email'] ?? 'someone@gmail.com', false),
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
                    _buildInfoRow('Disability / Diagnosis', _userProfile?['diagnosis'] ?? 'Knee Pain', false),
                    _buildDivider(false),
                    _buildInfoRow('Medications', _userProfile?['medications'] ?? 'Glucosamine', false),
                    _buildDivider(false),
                    _buildInfoRow('Assigned Doctor', _userProfile?['assignedDoctor'] ?? 'Dr. John Doe', false),
                    _buildDivider(false),
                    _buildInfoRow('Therapy Start Date', _userProfile?['therapyStartDate'] ?? 'December 4, 2025', false),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Feature under development'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      icon: Icon(Icons.edit, color: theme.primaryColor),
                      label: Text('Edit Information', style: TextStyle(color: theme.primaryColor)),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Feature under development'),
                            backgroundColor: Colors.orange,
                          ),
                        );
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

  Widget _buildInfoRow(String label, String value, bool isDark) {
    final theme = widget.themeProvider;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: theme.subtextColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
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