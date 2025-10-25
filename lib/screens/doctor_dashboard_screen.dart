import 'package:flutter/material.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/screens/more_screen.dart';
import 'package:demo_app/services/user_service.dart';
import 'package:demo_app/screens/manage_patient_exercise_screen.dart';
import 'package:demo_app/screens/manage_patient_records_screen.dart';
import 'package:demo_app/screens/view_patients_screen.dart';
import 'package:demo_app/screens/appointment_management_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_app/widgets/change_password_dialog.dart';


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
    // Enforce role after first frame to prevent unauthorized access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enforceRole();
    });
  }

  Future<void> _enforceRole() async {
    try {
      // Start with local cached role
  String role = UserService.getUserRole().toString().trim();

      // If a user is signed in, try to read authoritative role from Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final remoteRole = (data['role']?.toString() ?? '').trim();
          if (remoteRole.isNotEmpty) {
            role = remoteRole;
            await UserService.setUserRole(role);
          }
        }
      }

      // If the role is not 'doctor', redirect away
      if (role != 'doctor') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied — doctor account required.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushReplacementNamed(context, '/main');
        }
      }
    } catch (e) {
      // If anything goes wrong, be conservative and redirect
      if (mounted) Navigator.pushReplacementNamed(context, '/main');
    }
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.themeProvider.cardColor,
                        widget.themeProvider.cardColor.withOpacity(0.95),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.themeProvider.primaryColor.withOpacity(0.15),
                              widget.themeProvider.primaryColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.themeProvider.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 20,
                          color: widget.themeProvider.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: widget.themeProvider.textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Update your profile details',
                              style: TextStyle(
                                fontSize: 13,
                                color: widget.themeProvider.subtextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: widget.themeProvider.subtextColor,
                          size: 20,
                        ),
                      ),
              ],
            ),
          ),
                
                // Form content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: widget.themeProvider.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildEditableInfoRow(
                            'Full Name',
                            nameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your full name';
                              return null;
                            },
                          ),
                          _buildDivider(),
                          
                          _buildEditableInfoRow(
                            'Email Address',
                            emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your email';
                              if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          _buildDivider(),
                          
                          _buildEditableInfoRow(
                            'Contact Number',
                            contactController,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your contact number';
                              if (!RegExp(r'^\+?[\d\s-]{8,}$').hasMatch(value)) {
                                return 'Please enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                          _buildDivider(),
                          
                          _buildEditableInfoRow(
                            'Specialization / Expertise',
                            specializationController,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your specialization';
                              return null;
                            },
                          ),
                          _buildDivider(),
                          
                          _buildEditableInfoRow(
                            'License Number',
                            licenseController,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your license number';
                              return null;
                            },
                          ),
                          _buildDivider(),
                          
                          _buildEditableInfoRow(
                            'Years of Experience',
                            yearsController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter years of experience';
                              if (int.tryParse(value) == null) return 'Please enter a valid number';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Action buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: widget.themeProvider.backgroundColor.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.themeProvider.subtextColor.withOpacity(0.1),
                                widget.themeProvider.subtextColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.themeProvider.subtextColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.close_rounded,
                                    color: widget.themeProvider.subtextColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: widget.themeProvider.subtextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.themeProvider.primaryColor.withOpacity(0.1),
                                widget.themeProvider.primaryColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: widget.themeProvider.primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                final user = FirebaseAuth.instance.currentUser;
                final updated = {
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'contactNumber': contactController.text.trim(),
                  'specialization': specializationController.text.trim(),
                  'licenseNumber': licenseController.text.trim(),
                  'yearsOfExperience': yearsController.text.trim(),
                  'doctorId': user?.uid ?? '', // Add doctorId field
                };

                // Update local cache
                await UserService.updateUserProfile(updated);

                // Persist to Firestore
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
                    await docRef.set(updated, SetOptions(merge: true));
                  }
                } catch (e) {
                  // Handle error silently
                }

                // Reload local profile and close
                                if (mounted) {
                _loadProfile();
                Navigator.of(context).pop();
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.save_rounded,
                                    color: widget.themeProvider.primaryColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: widget.themeProvider.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _loadProfile() {
    _profile = {}; // default
    try {
      _profile = UserService.getUserProfile();
    } catch (e) {
      // Handle error silently
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = widget.themeProvider;
    final displayName = _profile['name'] ?? 'Surname, First Name';
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
                  // Profession Information (doctor-facing)
                  Text(
                    'Profession Information',
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
                          onPressed: () {
                            // Reuse the ChangePasswordDialog implemented in PatientDashboardScreen
                            showDialog(
                              context: context,
                              builder: (context) => ChangePasswordDialog(themeProvider: widget.themeProvider),
                            );
                          },
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
                  Row(
                    children: [
                      Expanded(
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ManagePatientRecordsScreen(themeProvider: themeProvider),
                              ),
                            );
                          },
                          icon: const Icon(Icons.folder_shared, size: 18),
                          label: const Text('Manage patient records'),
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
                  // New View Patients button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewPatientsScreen(themeProvider: themeProvider),
                          ),
                        );
                      },
                      icon: const Icon(Icons.people, size: 18),
                      label: const Text('View Patients'),
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
                  const SizedBox(height: 16),
                  // Appointment Management button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentManagementScreen(themeProvider: themeProvider),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Manage Appointments'),
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
                  
                  const SizedBox(height: 12),
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

  Widget _buildEditableInfoRow(String label, TextEditingController controller, {String? Function(String?)? validator, TextInputType? keyboardType}) {
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
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                errorStyle: const TextStyle(color: Colors.red),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    final theme = widget.themeProvider;
    return Divider(
      color: theme.cardColor.withOpacity(0.2),
      height: 1,
    );
  }
}