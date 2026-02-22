import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/screens/otp_verification_screen.dart';
import 'package:demo_app/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  final ThemeProvider? themeProvider;
  const RegisterScreen({super.key, this.themeProvider});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _selectedGender = 'Prefer not to say';
  final String _selectedRole = 'patient';

  // Step 2
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  // Character counts
  int _firstNameCount = 0;
  int _lastNameCount = 0;
  int _emailCount = 0;
  int _contactCount = 0;
  int _passwordCount = 0;
  int _confirmPasswordCount = 0;

  static const int _maxFieldLength = 100;
  static const int _hardBlockLength = 101;
  bool _tooLongDialogShown = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(() {
      setState(() => _firstNameCount = _firstNameController.text.length);
      _checkTooLong(_firstNameController);
    });
    _lastNameController.addListener(() {
      setState(() => _lastNameCount = _lastNameController.text.length);
      _checkTooLong(_lastNameController);
    });
    _emailController.addListener(() {
      setState(() => _emailCount = _emailController.text.length);
      _checkTooLong(_emailController);
    });
    _contactController.addListener(() {
      setState(() => _contactCount = _contactController.text.length);
      _checkTooLong(_contactController);
    });
    _passwordController.addListener(() {
      setState(() => _passwordCount = _passwordController.text.length);
      _checkTooLong(_passwordController);
    });
    _confirmPasswordController.addListener(() {
      setState(() => _confirmPasswordCount = _confirmPasswordController.text.length);
      _checkTooLong(_confirmPasswordController);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _checkTooLong(TextEditingController controller) {
    if (controller.text.length > _maxFieldLength && !_tooLongDialogShown) {
      _showTooLongDialog();
    }
  }

  void _showTooLongDialog() {
    _tooLongDialogShown = true;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Input Too Long',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Your input exceeds the maximum limit of $_maxFieldLength characters. Please shorten it.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: widget.themeProvider?.primaryColor ??
                    const Color(0xFF5B8EFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).then((_) => _tooLongDialogShown = false);
  }

  Widget _buildCharCounter(int count) {
    final bool atLimit = count >= _maxFieldLength;
    final bool nearLimit = count >= (_maxFieldLength * 0.85).round();
    final color = atLimit
        ? Colors.red
        : nearLimit
            ? Colors.orange
            : Colors.grey;
    return Text(
      '$count/$_maxFieldLength',
      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
    );
  }

  /// Returns standard inputFormatters: block whitespace + hard cap.
  /// [allowSpaces] — set true for name fields where spaces between words are OK.
  List<TextInputFormatter> _formatters({bool allowSpaces = false}) {
    return [
      if (!allowSpaces) FilteringTextInputFormatter.deny(RegExp(r'\s')),
      LengthLimitingTextInputFormatter(_hardBlockLength),
    ];
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Validation ───────────────────────────────────────────────────────────

  bool _validateStep1() {
    if (_firstNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your first name');
      return false;
    }
    if (_firstNameController.text.length > _maxFieldLength) {
      _showTooLongDialog();
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your last name');
      return false;
    }
    if (_lastNameController.text.length > _maxFieldLength) {
      _showTooLongDialog();
      return false;
    }
    if (_ageController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your age');
      return false;
    }
    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 1 || age > 120) {
      _showErrorSnackBar('Please enter a valid age');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your email');
      return false;
    }
    if (_emailController.text.length > _maxFieldLength) {
      _showTooLongDialog();
      return false;
    }
    if (_emailController.text.contains(' ')) {
      _showErrorSnackBar('Email must not contain spaces');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      _showErrorSnackBar('Please enter a valid email');
      return false;
    }
    if (_contactController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your contact number');
      return false;
    }
    if (_contactController.text.length > _maxFieldLength) {
      _showTooLongDialog();
      return false;
    }
    if (_passwordController.text.isEmpty) {
      _showErrorSnackBar('Please enter a password');
      return false;
    }
    if (_passwordController.text.length > _maxFieldLength) {
      _showTooLongDialog();
      return false;
    }
    // Whitespace check for password
    if (_passwordController.text.contains(' ') ||
        _passwordController.text.contains('\t') ||
        _passwordController.text.contains('\n')) {
      _showErrorSnackBar('Password must not contain spaces or whitespace');
      return false;
    }
    final password = _passwordController.text;
    final criteria = _passwordCriteria(password);
    final failed =
        criteria.entries.where((e) => !e.value).map((e) => e.key).toList();
    if (failed.isNotEmpty) {
      final friendly = failed.map((s) {
        switch (s) {
          case 'minLength':
            return 'at least 8 characters';
          case 'uppercase':
            return 'an uppercase letter';
          case 'lowercase':
            return 'a lowercase letter';
          case 'digit':
            return 'a number';
          case 'specialChar':
            return 'a special character (e.g. !@#\$%)';
          case 'notCommon':
            return 'avoid common passwords';
          default:
            return s;
        }
      }).join(', ');
      _showErrorSnackBar('Please use a stronger password: include $friendly.');
      return false;
    }
    if (_confirmPasswordController.text.length > _maxFieldLength) {
      _showTooLongDialog();
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return false;
    }
    if (!_agreedToTerms) {
      _showErrorSnackBar('Please agree to the terms and conditions');
      return false;
    }
    return true;
  }

  Map<String, bool> _passwordCriteria(String password) {
    final lower = password.toLowerCase();
    const common = [
      'password', '123456', '12345678', 'qwerty', 'abc123',
      'letmein', 'iloveyou', '111111', 'password1'
    ];
    return {
      'minLength': password.length >= 8,
      'uppercase': RegExp(r'[A-Z]').hasMatch(password),
      'lowercase': RegExp(r'[a-z]').hasMatch(password),
      'digit': RegExp(r'\d').hasMatch(password),
      'specialChar':
          RegExp(r'[!@#\$%\^&\*()_+\-=\[\]{};:\"\\|,.<>\/?]').hasMatch(password),
      'notCommon': !common.contains(lower),
    };
  }

  Widget _buildPasswordCriteriaWidget(ThemeProvider? theme) {
    final password = _passwordController.text;
    if (password.isEmpty) return const SizedBox.shrink();
    final criteria = _passwordCriteria(password);
    final okColor = Colors.green.shade600;
    final badColor = Colors.redAccent;

    Widget row(String label, bool ok) => Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Row(
            children: [
              Icon(
                ok ? Icons.check_circle : Icons.radio_button_unchecked,
                color: ok ? okColor : badColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: ok ? okColor : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: ok ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row('At least 8 characters', criteria['minLength'] ?? false),
          row('Contains an uppercase letter', criteria['uppercase'] ?? false),
          row('Contains a lowercase letter', criteria['lowercase'] ?? false),
          row('Contains a number', criteria['digit'] ?? false),
          row('Contains a special character', criteria['specialChar'] ?? false),
          row('Is not a common password', criteria['notCommon'] ?? false),
        ],
      ),
    );
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (_validateStep1()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentStep = 1);
    }
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentStep = 0);
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_validateStep2()) return;

    setState(() => _isLoading = true);

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text, // intentionally NOT trimmed
      );

      if (credential.user != null) {
        await credential.user!.sendEmailVerification();
        await UserService.setUserEmail(_emailController.text.trim());
        await UserService.updateUserProfile({
          'name':
              '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          'age': int.parse(_ageController.text.trim()),
          'gender': _selectedGender,
          'contactNumber': _contactController.text.trim(),
          'email': _emailController.text.trim(),
        });
        await UserService.setUserRole(_selectedRole);

        try {
          final users = FirebaseFirestore.instance.collection('users');
          final docRef = users.doc(credential.user!.uid);
          final existing = await docRef.get();
          final profileData = <String, dynamic>{
            'email': _emailController.text.trim(),
            'name':
                '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
            'contactNumber': _contactController.text.trim(),
            'gender': _selectedGender,
            'patientId': credential.user!.uid,
            'createdAt': FieldValue.serverTimestamp(),
          };

          final parsedAge = int.tryParse(_ageController.text.trim());
          if (parsedAge != null) profileData['age'] = parsedAge;

          if (!existing.exists) {
            profileData['role'] = 'patient';
            await docRef.set(profileData);
          } else {
            await docRef.update(profileData);
            try {
              final current = await docRef.get();
              final currentRole =
                  (current.data()?['role'] ?? '').toString().trim();
              if (currentRole.isEmpty) {
                await docRef.update({'role': 'patient'});
              }
            } catch (_) {}
          }
        } catch (e) {
          if (mounted) _showErrorSnackBar('Failed to save profile: $e');
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                themeProvider: widget.themeProvider,
                email: _emailController.text.trim(),
                contactNumber: _contactController.text.trim(),
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage =
              'The password is too weak. Use at least 8 characters with uppercase, lowercase, numbers, and special characters.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage =
              'An error occurred during registration. Please try again.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Terms dialog ─────────────────────────────────────────────────────────

  void _showTermsDialog(BuildContext context) {
    final theme = widget.themeProvider;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme?.primaryColor ?? const Color(0xFF5B8EFF),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Terms & Conditions',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last updated: October 25, 2025',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 24),
                        _buildTermsSection('App Usage Agreement',
                            'By using ChatPT, you agree to use this application solely for its intended purpose of physical therapy management. You must provide accurate information during registration and maintain the confidentiality of your account credentials. Any misuse of the application or violation of these terms may result in account termination.'),
                        const SizedBox(height: 20),
                        _buildTermsSection('Privacy Policy Summary',
                            'We collect and store your personal information, health data, and exercise progress to provide personalized physical therapy services. Your data is encrypted and stored securely. We do not share your personal information with third parties without your explicit consent, except as required by law or to provide essential services.'),
                        const SizedBox(height: 20),
                        _buildTermsSection('Liability Disclaimer',
                            'ChatPT is designed to assist with physical therapy management and should not replace professional medical advice. Users are responsible for consulting with qualified healthcare professionals before making any health-related decisions. We are not liable for any injuries, damages, or health complications that may arise from the use of this application.'),
                        const SizedBox(height: 20),
                        _buildTermsSection('Intellectual Property Notice',
                            'All content, features, and functionality of ChatPT, including but not limited to text, graphics, logos, and software, are owned by ChatPT and are protected by copyright and other intellectual property laws. Users may not reproduce, distribute, or create derivative works without written permission.'),
                        const SizedBox(height: 20),
                        _buildTermsSection('Contact Information',
                            'For questions, concerns, or support regarding these Terms & Conditions or the ChatPT application, please contact us at:\n\nEmail: support@chatpt.com\n\nWe will respond to your inquiries within 2-3 business days.'),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (theme?.primaryColor ??
                                    const Color(0xFF5B8EFF))
                                .withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (theme?.primaryColor ??
                                      const Color(0xFF5B8EFF))
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            'By continuing to use ChatPT, you acknowledge that you have read, understood, and agree to be bound by these Terms & Conditions.',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '© 2025 ChatPT. All rights reserved.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800])),
        const SizedBox(height: 8),
        Text(content,
            style:
                TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
      ],
    );
  }

  // ─── Input Builder Helper ─────────────────────────────────────────────────

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required List<TextInputFormatter> formatters,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final theme = widget.themeProvider;
    final primaryColor = theme?.primaryColor ?? const Color(0xFF5B8EFF);
    final inputFillColor = Colors.grey.withOpacity(0.08);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: formatters,
      decoration: InputDecoration(
        prefixIcon: Icon(prefixIcon, color: Colors.grey[500]),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        suffixIcon: suffixIcon,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;
    final primaryColor = theme?.primaryColor ?? const Color(0xFF5B8EFF);
    final bgColor = theme?.backgroundColor ?? Colors.white;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Column(
        children: [
          // ─── Header Section ───────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () {
                            if (_currentStep == 1) {
                              _previousStep();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        // Progress Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Step ${_currentStep + 1} of 2',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _currentStep == 0 ? 'Personal Info' : 'Account Security',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentStep == 0
                          ? 'Tell us a little bit about yourself'
                          : 'Secure your new ChatPT account',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // ─── Form Section (Bottom Sheet Style) ─────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(theme),
                    _buildStep2(theme),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 1 ───────────────────────────────────────────────────────────────

  Widget _buildStep1(ThemeProvider? theme) {
    final primaryColor = theme?.primaryColor ?? const Color(0xFF5B8EFF);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First Name
          _labelRow('First Name', _firstNameCount),
          const SizedBox(height: 8),
          _buildModernTextField(
            controller: _firstNameController,
            hintText: 'e.g. John',
            prefixIcon: Icons.person_outline,
            formatters: _formatters(allowSpaces: true),
          ),
          const SizedBox(height: 20),

          // Last Name
          _labelRow('Last Name', _lastNameCount),
          const SizedBox(height: 8),
          _buildModernTextField(
            controller: _lastNameController,
            hintText: 'e.g. Doe',
            prefixIcon: Icons.badge_outlined,
            formatters: _formatters(allowSpaces: true),
          ),
          const SizedBox(height: 20),

          // Age
          _labelRow('Age', 0, hideCounter: true),
          const SizedBox(height: 8),
          _buildModernTextField(
            controller: _ageController,
            hintText: 'Enter your age',
            prefixIcon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
          ),
          const SizedBox(height: 24),

          // Gender Selection
          _labelRow('Gender', 0, hideCounter: true),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ['Male', 'Female', 'Prefer not to say'].map((gender) {
              final isSelected = _selectedGender == gender;
              return GestureDetector(
                onTap: () => setState(() => _selectedGender = gender),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    gender,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),

          // Next Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 2,
                shadowColor: primaryColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Next Step',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2 ───────────────────────────────────────────────────────────────

  Widget _buildStep2(ThemeProvider? theme) {
    final primaryColor = theme?.primaryColor ?? const Color(0xFF5B8EFF);
    final textColor = theme?.textColor ?? const Color(0xFF1E293B);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email
          _labelRow('Email Address', _emailCount),
          const SizedBox(height: 8),
          _buildModernTextField(
            controller: _emailController,
            hintText: 'sample@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            formatters: _formatters(allowSpaces: false),
          ),
          const SizedBox(height: 20),

          // Contact
          _labelRow('Phone Number', _contactCount),
          const SizedBox(height: 8),
          _buildModernTextField(
            controller: _contactController,
            hintText: '+1 234 567 8900',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            formatters: _formatters(allowSpaces: false),
          ),
          const SizedBox(height: 20),

          // Password
          _labelRow('Password', _passwordCount),
          const SizedBox(height: 8),
          _buildModernTextField(
            controller: _passwordController,
            hintText: 'Create a password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            formatters: _formatters(allowSpaces: false),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[500],
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          AnimatedBuilder(
            animation: _passwordController,
            builder: (_, __) => _buildPasswordCriteriaWidget(theme),
          ),
          const SizedBox(height: 4),

          // Confirm Password
          _labelRow('Confirm Password', _confirmPasswordCount),
          const SizedBox(height: 8),
          _buildModernTextField(
            controller: _confirmPasswordController,
            hintText: 'Re-enter your password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            formatters: _formatters(allowSpaces: false),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[500],
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          const SizedBox(height: 24),

          // Terms Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                  activeColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: BorderSide(color: Colors.grey[400]!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8)),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => _showTermsDialog(context),
                          child: Text(
                            'Terms and Conditions',
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Actions
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(color: Colors.grey[300]!, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 2,
                    shadowColor: primaryColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24), // Extra padding for safety
        ],
      ),
    );
  }

  // ─── Shared label + counter row ───────────────────────────────────────────

  Widget _labelRow(String label, int count, {bool hideCounter = false}) {
    final textColor = widget.themeProvider?.textColor ?? const Color(0xFF1E293B);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        if (!hideCounter) _buildCharCounter(count),
      ],
    );
  }
}