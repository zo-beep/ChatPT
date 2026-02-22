import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Character counts
  int _emailCharCount = 0;
  int _passwordCharCount = 0;

  static const int _maxFieldLength = 100;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();

    _emailController.addListener(() {
      setState(() {
        _emailCharCount = _emailController.text.length;
        if (_emailErrorText != null) _emailErrorText = null;
        // Show inline error if over limit
        if (_emailCharCount > _maxFieldLength) {
          _emailErrorText = 'Input is too long (max $_maxFieldLength characters)';
        }
      });
    });

    _passwordController.addListener(() {
      setState(() {
        _passwordCharCount = _passwordController.text.length;
        if (_passwordErrorText != null) _passwordErrorText = null;
        if (_passwordCharCount > _maxFieldLength) {
          _passwordErrorText = 'Input is too long (max $_maxFieldLength characters)';
        }
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Validators ───────────────────────────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (value.length > _maxFieldLength) {
      return 'Input is too long (max $_maxFieldLength characters)';
    }
    // Reject if email contains whitespace anywhere
    if (value.contains(' ')) {
      return 'Email must not contain spaces';
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
    if (value.length > _maxFieldLength) {
      return 'Input is too long (max $_maxFieldLength characters)';
    }
    // Reject passwords that contain whitespace (leading, trailing, or internal)
    if (value.contains(' ') || value.contains('\t') || value.contains('\n')) {
      return 'Password must not contain spaces or whitespace';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Returns a counter widget that turns red when approaching or at the limit.
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

  // ─── Login handler ────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    // Clear any server-side errors before re-validating
    setState(() {
      _emailErrorText = null;
      _passwordErrorText = null;
    });

    if (!_formKey.currentState!.validate()) return;

    // Extra guard: reject if over limit (shouldn't reach here due to inputFormatters,
    // but kept as a safety net)
    if (_emailController.text.length > _maxFieldLength ||
        _passwordController.text.length > _maxFieldLength) {
      _showErrorSnackBar(
          'One or more fields exceed the maximum length of $_maxFieldLength characters.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Trim email only — do NOT trim password (whitespace in password is now invalid)
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text, // intentionally NOT trimmed
      );

      if (credential.user != null) {
        if (_rememberMe) {
          await UserService.saveRememberMeCredentials(
            _emailController.text.trim(),
            _passwordController.text,
          );
        } else {
          await UserService.clearRememberMeCredentials();
        }

        await UserService.setUserEmail(_emailController.text.trim());

        try {
          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid);
          final doc = await docRef.get();

          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final role = (data['role']?.toString() ?? '').trim();
            final normalizedRole = role.isEmpty ? 'patient' : role;

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

            if (mounted) Navigator.pushReplacementNamed(context, '/main');
          } else {
            await UserService.setUserRole('patient');
            if (mounted) Navigator.pushReplacementNamed(context, '/main');
          }
        } catch (e) {
          print('Failed to read Firestore user doc at login: $e');
          await UserService.setUserRole('patient');
          if (mounted) Navigator.pushReplacementNamed(context, '/main');
        }
      }
    } on FirebaseAuthException catch (e) {
      final code = e.code.toString().toLowerCase();
      final message = (e.message ?? '').toString().toLowerCase();

      bool handled = false;

      if (code.contains('user-not-found') ||
          code.contains('user_not_found') ||
          code.contains('no-such-user') ||
          message.contains('no user') ||
          message.contains('user not found') ||
          message.contains('no user record')) {
        setState(() => _emailErrorText = 'No account is registered with this email.');
        handled = true;
      }

      if (!handled &&
          (code.contains('wrong-password') ||
              code.contains('wrong_password') ||
              message.contains('wrong password') ||
              message.contains('invalid password'))) {
        setState(() => _passwordErrorText = 'Incorrect password.');
        handled = true;
      }

      if (!handled &&
          (code.contains('invalid-credential') ||
              code.contains('invalid_credential') ||
              message.contains('supplied auth credential is incorrect') ||
              message.contains('has expired') ||
              message.contains('invalid credential'))) {
        setState(() => _passwordErrorText =
            'Incorrect credentials or expired token. Try again or reset your password.');
        handled = true;
      }

      if (!handled &&
          (code.contains('invalid-email') ||
              code.contains('invalid_email') ||
              message.contains('invalid email'))) {
        setState(() => _emailErrorText = 'The email address is not valid.');
        handled = true;
      }

      if (!handled) {
        if (code.contains('user-disabled') || message.contains('disabled')) {
          _showErrorSnackBar('This user account has been disabled.');
          handled = true;
        } else if (code.contains('too-many-requests') ||
            message.contains('too many requests')) {
          _showErrorSnackBar('Too many failed attempts. Please try again later.');
          handled = true;
        } else if (code.contains('operation-not-allowed') ||
            message.contains('operation not allowed')) {
          _showErrorSnackBar('Email/password accounts are not enabled.');
          handled = true;
        }
      }

      if (!handled) {
        if (kDebugMode) {
          _showErrorSnackBar('Auth error: code=${e.code} message=${e.message ?? 'null'}');
        } else {
          _showErrorSnackBar('An error occurred during login. Please try again.');
        }
      }
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Forgot password ──────────────────────────────────────────────────────

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your email address first.');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text.trim())) {
      _showErrorSnackBar('Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to ${_emailController.text.trim()}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Remember me ──────────────────────────────────────────────────────────

  Future<void> _loadRememberedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberedEmail = prefs.getString('remembered_email');
      final rememberedPassword = prefs.getString('remembered_password');
      final rememberMeEnabled = prefs.getBool('remember_me') ?? false;

      if (rememberMeEnabled &&
          rememberedEmail != null &&
          rememberedPassword != null) {
        setState(() {
          _emailController.text = rememberedEmail;
          _passwordController.text = rememberedPassword;
          _emailCharCount = rememberedEmail.length;
          _passwordCharCount = rememberedPassword.length;
          _rememberMe = true;
        });
      } else {
        final isRememberMeEnabled = await UserService.isRememberMeEnabled();
        if (isRememberMeEnabled) {
          final credentials = await UserService.getRememberedCredentials();
          if (credentials['email'] != null && credentials['password'] != null) {
            setState(() {
              _emailController.text = credentials['email']!;
              _passwordController.text = credentials['password']!;
              _emailCharCount = credentials['email']!.length;
              _passwordCharCount = credentials['password']!.length;
              _rememberMe = true;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading remembered credentials: $e');
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeProvider;
    final primaryColor = theme?.primaryColor ?? const Color(0xFF5B8EFF);
    final bgColor = theme?.backgroundColor ?? Colors.white;
    final textColor = theme?.textColor ?? const Color(0xFF1E293B);
    final inputFillColor = Colors.grey.withOpacity(0.08);

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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Modern Back Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                    ),
                    const SizedBox(height: 16),
                    // Logo & Greetings
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.directions_run,
                        size: 38,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your ChatPT account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Email ──────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Email Address',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            _buildCharCounter(_emailCharCount),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            LengthLimitingTextInputFormatter(_maxFieldLength),
                          ],
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[500]),
                            hintText: 'sample@email.com',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: inputFillColor,
                            errorText: _emailErrorText,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Password ───────────────────────────────────
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: _validatePassword,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            LengthLimitingTextInputFormatter(_maxFieldLength),
                          ],
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500]),
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: inputFillColor,
                            errorText: _passwordErrorText,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey[500],
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

                        // ── Controls Row (Remember Me & Forgot Pass) ───
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: _isLoading
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                    activeColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    side: BorderSide(color: Colors.grey[400]!),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remember me',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textColor.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _isLoading ? null : _handleForgotPassword,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // ── Login Button ───────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
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
                                    'Sign In',
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}