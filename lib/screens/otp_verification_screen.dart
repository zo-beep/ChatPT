import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo_app/main.dart';
import 'package:demo_app/screens/login_screen.dart';
import 'package:demo_app/services/user_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final ThemeProvider? themeProvider;
  final String email;
  final String contactNumber;

  const OTPVerificationScreen({
    super.key,
    this.themeProvider,
    required this.email,
    required this.contactNumber,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 60;
  bool _canResend = false;
  bool _isAutoChecking = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startAutoCheck();
  }

  void _startAutoCheck() {
    // Check every 3 seconds if email is verified
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isLoading && !_isAutoChecking) {
        _checkEmailVerification();
      }
    });
  }

  Future<void> _checkEmailVerification() async {
    if (_isAutoChecking) return;
    
    setState(() {
      _isAutoChecking = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final currentUser = FirebaseAuth.instance.currentUser;
        
        if (currentUser != null && currentUser.emailVerified) {
          _showSuccessSnackBar('Email verified successfully!');
          if (mounted) {
            // Redirect to appropriate dashboard based on user role
            final dashboardRoute = UserService.getDashboardRoute();
            Navigator.pushReplacementNamed(context, dashboardRoute);
          }
          return;
        }
      }
    } catch (e) {
      // Silently handle errors during auto-check
    } finally {
      if (mounted) {
        setState(() {
          _isAutoChecking = false;
        });
        // Continue auto-checking
        _startAutoCheck();
      }
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _resendCountdown--;
          if (_resendCountdown <= 0) {
            _canResend = true;
          } else {
            _startCountdown();
          }
        });
      }
    });
  }

  String? _validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'OTP must contain only numbers';
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

  Future<void> _verifyOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Reload user to get the latest verification status
        await user.reload();
        final currentUser = FirebaseAuth.instance.currentUser;
        
        if (currentUser != null && currentUser.emailVerified) {
          _showSuccessSnackBar('Email verified successfully!');
          if (mounted) {
            // Redirect to appropriate dashboard based on user role
            final dashboardRoute = UserService.getDashboardRoute();
            Navigator.pushReplacementNamed(context, dashboardRoute);
          }
        } else {
          _showErrorSnackBar('Email not yet verified. Please check your email and click the verification link, then try again.');
        }
      } else {
        _showErrorSnackBar('No user found. Please try registering again.');
      }
    } catch (e) {
      _showErrorSnackBar('Verification failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isResending = true;
      _canResend = false;
      _resendCountdown = 60;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        _showSuccessSnackBar('Verification email sent!');
        _startCountdown();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to resend verification email.');
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
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
                  const SizedBox(height: 40),
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
                            'Verify Your Email',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme?.textColor ?? Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We\'ve sent a verification link to:',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme?.subtextColor ?? Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.email,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme?.primaryColor ?? const Color(0xFF5B8EFF),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme?.primaryColor?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme?.primaryColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: theme?.primaryColor ?? const Color(0xFF5B8EFF),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Next Steps:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: theme?.primaryColor ?? const Color(0xFF5B8EFF),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '1. Check your email inbox (and spam folder)\n2. Click the verification link in the email\n3. This app will automatically detect when you\'ve verified your email',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme?.textColor ?? Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          theme?.primaryColor ?? const Color(0xFF5B8EFF),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Automatically checking for verification...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme?.subtextColor ?? Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verifyOTP,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme?.primaryColor ?? const Color(0xFF5B8EFF),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[300],
                                disabledForegroundColor: Colors.grey[500],
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Check Verification Status',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Didn\'t receive the email? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme?.subtextColor ?? Colors.grey[600],
                                ),
                              ),
                              GestureDetector(
                                onTap: _canResend ? _resendOTP : null,
                                child: Text(
                                  _canResend
                                      ? 'Resend'
                                      : 'Resend in ${_resendCountdown}s',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _canResend
                                        ? (theme?.primaryColor ?? const Color(0xFF5B8EFF))
                                        : Colors.grey[400],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isResending) ...[
                            const SizedBox(height: 8),
                            const Center(
                              child: SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              ),
                            ),
                          ],
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
    _otpController.dispose();
    super.dispose();
  }
}
