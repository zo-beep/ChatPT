import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    
    // Also persist these fields to Firestore so admins and other clients can access them
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
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
        };

        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await docRef.set(profileData, SetOptions(merge: true));
        print('Saved patient profile to Firestore for ${user.uid}');
      } else {
        print('No authenticated user; skipping Firestore save');
      }
    } catch (e) {
      print('Failed to save patient profile to Firestore: $e');
    }

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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ChangePasswordDialog(themeProvider: widget.themeProvider);
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

class ChangePasswordDialog extends StatefulWidget {
  final ThemeProvider themeProvider;

  const ChangePasswordDialog({super.key, required this.themeProvider});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  
  String _passwordStrength = '';
  double _passwordStrengthValue = 0.0;
  Color _passwordStrengthColor = Colors.grey;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _calculatePasswordStrength(String password) {
    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    setState(() {
      _passwordStrengthValue = score / 5.0;
      
      if (score <= 2) {
        _passwordStrength = 'Weak';
        _passwordStrengthColor = Colors.red;
      } else if (score <= 3) {
        _passwordStrength = 'Fair';
        _passwordStrengthColor = Colors.orange;
      } else if (score <= 4) {
        _passwordStrength = 'Good';
        _passwordStrengthColor = Colors.blue;
      } else {
        _passwordStrength = 'Strong';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current password is required';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'New password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (value == _currentPasswordController.text) {
      return 'New password must be different from current password';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your new password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('No user logged in');
        return;
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text.trim());

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessSnackBar('Password changed successfully!');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Current password is incorrect';
          break;
        case 'weak-password':
          errorMessage = 'New password is too weak';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please log in again to change your password';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later';
          break;
        default:
          errorMessage = 'Failed to change password: ${e.message}';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      color: theme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update your account password',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Current Password Field
              Text(
                'Current Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                validator: _validateCurrentPassword,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Enter your current password',
                  hintStyle: TextStyle(color: theme.subtextColor),
                  prefixIcon: Icon(Icons.lock_outline, color: theme.primaryColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                      color: theme.subtextColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 20),
              
              // New Password Field
              Text(
                'New Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                validator: _validateNewPassword,
                onChanged: _calculatePasswordStrength,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Enter your new password',
                  hintStyle: TextStyle(color: theme.subtextColor),
                  prefixIcon: Icon(Icons.lock_outline, color: theme.primaryColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                      color: theme.subtextColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              
              // Password Strength Indicator
              if (_newPasswordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _passwordStrengthValue,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _passwordStrength,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _passwordStrengthColor,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              
              // Confirm Password Field
              Text(
                'Confirm New Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                validator: _validateConfirmPassword,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Confirm your new password',
                  hintStyle: TextStyle(color: theme.subtextColor),
                  prefixIcon: Icon(Icons.lock_outline, color: theme.primaryColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: theme.subtextColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.subtextColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: theme.subtextColor.withOpacity(0.3)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Change Password'),
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
}