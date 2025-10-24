
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_app/screens/doctor_dashboard_screen.dart';
import 'package:demo_app/screens/admin_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// LOGIN SCREEN
class LoginScreen extends StatefulWidget {
  final ThemeProvider? themeProvider;
  const LoginScreen({super.key, this.themeProvider});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailErrorText;
  String? _passwordErrorText;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@')) {
      return 'Invalid email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (credential.user != null) {
        // Handle remember me functionality
        if (_rememberMe) {
          await UserService.saveRememberMeCredentials(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        } else {
          await UserService.clearRememberMeCredentials();
        }

        // Set user email in UserService
        await UserService.setUserEmail(_emailController.text.trim());

        // Try to fetch role from Firestore
        try {
          final docRef = FirebaseFirestore.instance.collection('users').doc(credential.user!.uid);
          final doc = await docRef.get();

          // If a Firestore profile exists, merge it into UserService so UI shows real values
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final role = (data['role']?.toString() ?? '').trim();
            // Normalize role
            final normalizedRole = role.isEmpty ? 'patient' : role;

            // Update local cache/service with available fields
            await UserService.updateUserProfile({
              'name': data['name'] ?? _emailController.text.trim(),
              'email': data['email'] ?? _emailController.text.trim(),
              'age': data['age'],
              'gender': data['gender'],
              'contactNumber': data['contactNumber'],
              'role': normalizedRole,
              'patientId': credential.user!.uid,
            });

            await UserService.setUserRole(normalizedRole);

            if (mounted) {
              if (normalizedRole == 'doctor') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => DoctorDashboardScreen(themeProvider: widget.themeProvider!)),
                  );
                } else if (normalizedRole == 'admin') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AdminDashboardScreen(themeProvider: widget.themeProvider!)),
                  );
                } else {
                  Navigator.pushReplacementNamed(context, '/main');
                }
            }
          } else {
            // No Firestore doc; ensure role saved and proceed
            await UserService.setUserRole('patient');
            if (mounted) Navigator.pushReplacementNamed(context, '/main');
          }
        } catch (e) {
          // Fallback to main screen if Firestore read fails
          print('Failed to read Firestore user doc at login: $e');
          await UserService.setUserRole('patient');
          if (mounted) Navigator.pushReplacementNamed(context, '/main');
        }
      }
    } on FirebaseAuthException catch (e) {
      // Normalize code and message to be more forgiving across platforms
  final code = e.code.toString().toLowerCase();
  final message = (e.message ?? '').toString().toLowerCase();

      bool handled = false;

      // user-not-found variants
      if (code.contains('user-not-found') || code.contains('user_not_found') || code.contains('no-such-user') ||
          message.contains('no user') || message.contains('user not found') || message.contains('no user record')) {
        setState(() {
          _emailErrorText = 'No account is registered with this email.';
        });
        handled = true;
      }

      // wrong-password variants
      if (!handled && (code.contains('wrong-password') || code.contains('wrong_password') || message.contains('wrong password') || message.contains('invalid password'))) {
        setState(() {
          _passwordErrorText = 'Incorrect password.';
        });
        handled = true;
      }

      // invalid-credential (e.g. "the supplied auth credential is incorrect or has expired")
      if (!handled && (code.contains('invalid-credential') || code.contains('invalid_credential') || message.contains('supplied auth credential is incorrect') || message.contains('has expired') || message.contains('invalid credential'))) {
        setState(() {
          _passwordErrorText = 'Incorrect credentials or expired token. Try again or reset your password.';
        });
        handled = true;
      }

      // invalid-email
      if (!handled && (code.contains('invalid-email') || code.contains('invalid_email') || message.contains('invalid email'))) {
        setState(() {
          _emailErrorText = 'The email address is not valid.';
        });
        handled = true;
      }

      // Other known account-level errors
      if (!handled) {
        if (code.contains('user-disabled') || message.contains('disabled')) {
          _showErrorSnackBar('This user account has been disabled.');
          handled = true;
        } else if (code.contains('too-many-requests') || message.contains('too many requests')) {
          _showErrorSnackBar('Too many failed attempts. Please try again later.');
          handled = true;
        } else if (code.contains('operation-not-allowed') || message.contains('operation not allowed')) {
          _showErrorSnackBar('Email/password accounts are not enabled.');
          handled = true;
        }
      }

      if (!handled) {
        // In debug builds show raw code/message to help tune matching
        if (kDebugMode) {
          final raw = 'code=${e.code} message=${e.message ?? 'null'}';
          _showErrorSnackBar('Auth error: $raw');
        } else {
          _showErrorSnackBar('An error occurred during login. Please try again.');
        }
      }
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

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your email address first.');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      _showErrorSnackBar('Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to ${_emailController.text.trim()}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = 'Failed to send password reset email. Please try again.';
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
    return Scaffold(
      body: Container(
        color: theme?.primaryColor ?? const Color(0xFF5B8EFF),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.directions_run,
                          size: 35,
                          color: theme?.primaryColor ?? const Color(0xFF5B8EFF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'ChatPT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme?.cardColor ?? Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme?.textColor ?? Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                            decoration: InputDecoration(
                              hintText: 'sample@email.com',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: theme?.backgroundColor ?? Colors.grey[50],
                              errorText: _emailErrorText,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme?.textColor ?? Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: _validatePassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: theme?.backgroundColor ?? Colors.grey[50],
                              errorText: _passwordErrorText,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Remember Me Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: _isLoading ? null : (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: theme?.primaryColor ?? const Color(0xFF5B8EFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Remember me',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme?.textColor ?? Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Forgot Password Link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _handleForgotPassword,
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: theme?.primaryColor ?? const Color(0xFF5B8EFF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme?.cardColor ?? Colors.white,
                                foregroundColor: theme?.primaryColor ?? const Color(0xFF5B8EFF),
                                disabledBackgroundColor: Colors.grey[300],
                                disabledForegroundColor: Colors.grey[500],
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: theme?.primaryColor ?? const Color(0xFF5B8EFF),
                                    width: 1,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
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
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
    _emailController.addListener(() {
      if (_emailErrorText != null) {
        setState(() {
          _emailErrorText = null;
        });
      }
    });
    _passwordController.addListener(() {
      if (_passwordErrorText != null) {
        setState(() {
          _passwordErrorText = null;
        });
      }
    });
  }

  Future<void> _loadRememberedCredentials() async {
    try {
      // First try to load from SharedPreferences (fallback)
      final prefs = await SharedPreferences.getInstance();
      final rememberedEmail = prefs.getString('remembered_email');
      final rememberedPassword = prefs.getString('remembered_password');
      final rememberMeEnabled = prefs.getBool('remember_me') ?? false;
      
      if (rememberMeEnabled && rememberedEmail != null && rememberedPassword != null) {
        setState(() {
          _emailController.text = rememberedEmail;
          _passwordController.text = rememberedPassword;
          _rememberMe = true;
        });
        print('Loaded remembered credentials from SharedPreferences');
      } else {
        // Try to load from Firestore if user is already authenticated
        final isRememberMeEnabled = await UserService.isRememberMeEnabled();
        if (isRememberMeEnabled) {
          final credentials = await UserService.getRememberedCredentials();
          if (credentials['email'] != null && credentials['password'] != null) {
            setState(() {
              _emailController.text = credentials['email']!;
              _passwordController.text = credentials['password']!;
              _rememberMe = true;
            });
            print('Loaded remembered credentials from Firestore');
          }
        }
      }
    } catch (e) {
      print('Error loading remembered credentials: $e');
    }
  }
}