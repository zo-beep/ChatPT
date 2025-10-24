import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/services/user_service.dart';
import 'package:demo_app/widgets/change_password_dialog.dart';

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
  final _formKey = GlobalKey<FormState>();
  Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    // Load cached profile first for a fast paint
    setState(() {
      _userProfile = UserService.getUserProfile();
      _initializeControllers();
      _isLoading = false;
    });

    // Then hydrate with the latest data from Firestore so doctor-updated
    // medical fields (diagnosis, medications, etc.) become visible to patients
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          setState(() {
            // Merge remote into local
            _userProfile = {
              if (_userProfile != null) ..._userProfile!,
              ...data,
            };

            // Update existing controllers with latest values
            for (final entry in data.entries) {
              final key = entry.key;
              final value = entry.value;
              if (_controllers.containsKey(key)) {
                _controllers[key]!.text = value?.toString() ?? '';
              }
            }
          });
        }
      }
    } catch (e) {
      // Non-fatal: fall back to cached profile if online fetch fails
      print('Failed to hydrate patient profile from Firestore: $e');
    }
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
        'height': TextEditingController(text: _userProfile!['height'] ?? ''),
        'weight': TextEditingController(text: _userProfile!['weight'] ?? ''),
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
          onPressed: () => Navigator.pop(context),
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
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SafeArea(
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
                                Expanded(
                                  child: Column(
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
                                    ],
                                  ),
                                ),
                                Builder(builder: (context) {
                                  final role = (_userProfile?['role'] ?? '').toString().trim();
                                  final roleLabel = role.isEmpty ? 'Patient' : (role[0].toUpperCase() + role.substring(1));
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor,
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
                                  );
                                }),
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
                            _buildEditableInfoRow('Name', 'name', validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Name is required';
                              }
                              if (value.length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            }),
                            _buildDivider(false),
                            _buildEditableInfoRow('Age', 'age', validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              final age = int.tryParse(value);
                              if (age == null) return 'Please enter a valid number';
                              if (age < 0 || age > 120) return 'Please enter a valid age (0-120)';
                              return null;
                            }),
                            _buildDivider(false),
                            _buildEditableInfoRow('Gender', 'gender'),
                            _buildDivider(false),
                            _buildEditableInfoRow('Contact No.', 'contactNumber', validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              if (!RegExp(r'^\+?[\d\s-]{8,}$').hasMatch(value)) {
                                return 'Please enter a valid phone number';
                              }
                              return null;
                            }),
                            _buildDivider(false),
                            _buildEditableInfoRow('Email', 'email', validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            }),
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
                            _buildDatePickerRow('Therapy Start Date', 'therapyStartDate'),
                            _buildDivider(false),
                            _buildEditableInfoRow('Height (cm)', 'height', validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              final height = double.tryParse(value);
                              if (height == null) return 'Please enter a valid number';
                              if (height < 0 || height > 300) return 'Please enter a valid height (0-300 cm)';
                              return null;
                            }),
                            _buildDivider(false),
                            _buildEditableInfoRow('Weight (kg)', 'weight', validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              final weight = double.tryParse(value);
                              if (weight == null) return 'Please enter a valid number';
                              if (weight < 0 || weight > 500) return 'Please enter a valid weight (0-500 kg)';
                              return null;
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showChangePasswordDialog(),
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
      ),
    );
  }

  Widget _buildEditableInfoRow(String label, String fieldKey, {String? Function(String?)? validator}) {
    final theme = widget.themeProvider;
    final medInfoFields = {
      'diagnosis',
      'medications',
      'assignedDoctor',
      'therapyStartDate',
      'height',
      'weight',
    };

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
            child: (_isEditing && !medInfoFields.contains(fieldKey))
                ? TextFormField(
                    controller: _controllers[fieldKey],
                    validator: validator,
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

  Widget _buildDatePickerRow(String label, String fieldKey) {
    final theme = widget.themeProvider;
    final medInfoFields = {
      'diagnosis',
      'medications',
      'assignedDoctor',
      'therapyStartDate',
      'height',
      'weight',
    };

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
            child: (_isEditing && !medInfoFields.contains(fieldKey))
                ? InkWell(
                    onTap: () => _selectDate(fieldKey),
                    child: InputDecorator(
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
                        suffixIcon: Icon(Icons.calendar_today, color: theme.primaryColor),
                      ),
                      child: Text(
                        _controllers[fieldKey]?.text ?? 'Select Date',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textColor,
                        ),
                      ),
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

  Widget _buildDivider(bool isDark) {
    final theme = widget.themeProvider;
    return Divider(
      color: theme.cardColor.withOpacity(0.2),
      height: 1,
    );
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = true;
    });
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => ChangePasswordDialog(themeProvider: widget.themeProvider),
    );
  }

  Future<void> _selectDate(String fieldKey) async {
    final theme = widget.themeProvider;
    final initialDate = DateTime.tryParse(_controllers[fieldKey]?.text ?? '') ?? DateTime.now();
    
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1900),
        lastDate: DateTime(2101),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: theme.primaryColor,
              ),
            ),
            child: child!,
          );
        },
      );
    
      if (picked != null) {
        setState(() {
          _controllers[fieldKey]?.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting date: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isEditing = false;
    });
    
    final profileData = {
      'name': _controllers['name']?.text ?? '',
      'patientId': _controllers['patientId']?.text ?? '',
      'age': int.tryParse(_controllers['age']?.text ?? ''),
      'gender': _controllers['gender']?.text ?? '',
      'contactNumber': _controllers['contactNumber']?.text ?? '',
      'email': _controllers['email']?.text ?? '',
      'diagnosis': _controllers['diagnosis']?.text ?? '',
      'medications': _controllers['medications']?.text ?? '',
      'assignedDoctor': _controllers['assignedDoctor']?.text ?? '',
      'therapyStartDate': _controllers['therapyStartDate']?.text ?? '',
      'height': _controllers['height']?.text ?? '',
      'weight': _controllers['weight']?.text ?? '',
    };

    // Update UserService
    await UserService.updateUserProfile(profileData);
    
    // Update Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(profileData, SetOptions(merge: true));
        
        print('Saved patient profile to Firestore for ${user.uid}');
      } else {
        print('No authenticated user; skipping Firestore save');
      }
    } catch (e) {
      print('Failed to save patient profile to Firestore: $e');
    }

    // Update local state
    if (_userProfile != null) {
      _userProfile!.addAll(profileData);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}