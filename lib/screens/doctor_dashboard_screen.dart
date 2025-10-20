import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/screens/more_screen.dart';
import 'package:demo_app/services/user_service.dart';
import 'package:demo_app/screens/manage_patient_exercise_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// DOCTOR DASHBOARD SCREEN
class DoctorDashboardScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const DoctorDashboardScreen({super.key, required this.themeProvider});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _showEditDialog() {
    final TextEditingController nameController = TextEditingController(text: _profile['name'] ?? '');
    final TextEditingController emailController = TextEditingController(text: _profile['email'] ?? '');
    final TextEditingController contactController = TextEditingController(text: _profile['contactNumber'] ?? '');
    final TextEditingController specializationController = TextEditingController(text: _profile['specialization'] ?? '');
    final TextEditingController licenseController = TextEditingController(text: _profile['licenseNumber'] ?? '');
    final TextEditingController yearsController = TextEditingController(text: _profile['yearsOfExperience']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: contactController, decoration: const InputDecoration(labelText: 'Contact')),
                const SizedBox(height: 12),
                TextField(controller: specializationController, decoration: const InputDecoration(labelText: 'Specialization / Expertise')),
                TextField(controller: licenseController, decoration: const InputDecoration(labelText: 'License Number')),
                TextField(controller: yearsController, decoration: const InputDecoration(labelText: 'Years of Experience')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = {
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'contactNumber': contactController.text.trim(),
                  'specialization': specializationController.text.trim(),
                  'licenseNumber': licenseController.text.trim(),
                  'yearsOfExperience': yearsController.text.trim(),
                };

                // Update local cache
                await UserService.updateUserProfile(updated);

                // Persist to Firestore
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
                    await docRef.set(updated, SetOptions(merge: true));
                    print('Saved doctor profile to Firestore for ${user.uid}');
                  }
                } catch (e) {
                  print('Failed to save doctor profile to Firestore: $e');
                }

                // Reload local profile and close
                _loadProfile();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _loadProfile() {
    _profile = {}; // default
    try {
      _profile = UserService.getUserProfile();
    } catch (e) {
      print('Failed to load user profile: $e');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = widget.themeProvider;
    final displayName = _profile['name'] ?? 'Surname, First Name';
    final uidDisplay = _profile['patientId'] ?? 'UID: #000002';
    final role = (_profile['role'] ?? '').toString().trim();
    final roleLabel = role.isEmpty ? 'Doctor' : (role[0].toUpperCase() + role.substring(1));

    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeProvider.cardColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: themeProvider.primaryColor),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MoreScreen(themeProvider: themeProvider)),
                );
              },
            ),
            title: Text(
              'Back',
              style: TextStyle(color: themeProvider.primaryColor),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello! Welcome to your dashboard.',
                    style: TextStyle(
                      fontSize: 16,
                      color: themeProvider.subtextColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: themeProvider.primaryColor.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.primaryColor.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: themeProvider.secondaryColor.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 38,
                            color: themeProvider.secondaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: themeProvider.textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                uidDisplay,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: themeProvider.subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: themeProvider.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            roleLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
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
                      color: themeProvider.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTable(
                    themeProvider,
                    [
                      ['Name', displayName],
                      ['Age', (_profile['age'] ?? '').toString().isEmpty ? '—' : _profile['age'].toString()],
                      ['Gender', _profile['gender'] ?? '—'],
                      ['Contact No#', _profile['contactNumber'] ?? '—'],
                      ['Email', _profile['email'] ?? '—'],
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Medical Information
                  Text(
                    'Medical Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTable(
                    themeProvider,
                    [
                      ['Specialization/\nExpertise', _profile['specialization'] ?? '—'],
                      ['License Number', _profile['licenseNumber'] ?? '—'],
                      ['Years of\nExperience', _profile['yearsOfExperience']?.toString() ?? '—'],
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditDialog(),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit Information'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: themeProvider.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: themeProvider.primaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.lock, size: 18),
                          label: const Text('Change Password'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: themeProvider.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: themeProvider.primaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManagePatientExerciseScreen(themeProvider: themeProvider),
                          ),
                        );
                      },
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: const Text('Manage patient exercises'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: themeProvider.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: themeProvider.primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTable(ThemeProvider theme, List<List<String>> data) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < data.length; i++) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      data[i][0],
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.subtextColor,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      data[i][1],
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
            ),
            if (i < data.length - 1)
              Divider(
                height: 1,
                color: theme.primaryColor.withOpacity(0.1),
              ),
          ],
        ],
      ),
    );
  }
}