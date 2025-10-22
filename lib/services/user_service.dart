import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo_app/services/notification_service.dart';
import 'dart:convert';
import 'dart:math';

class UserService {
  static String _currentUserName = 'Jane Doe';
  static String? _customAvatar;
  static Map<String, dynamic> _userProfile = {
    'name': 'Jane Doe',
    'patientId': '001-2345-678',
    'age': 25,
    'gender': 'Female',
    'contactNumber': '09123456789',
    'email': 'jane.doe@example.com',
    'diagnosis': '',
    'medications': '',
    'assignedDoctor': '',
    'therapyStartDate': '',
    // Doctor-specific fields (may be empty for patients)
    'specialization': '',
    'licenseNumber': '',
    'yearsOfExperience': '',
    'role': 'patient', // default role
  };

  // Initialize SharedPreferences
  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // Load user data from SharedPreferences
  static Future<void> loadUserData() async {
    final prefs = await _prefs;
    
    // Load user name
    _currentUserName = prefs.getString('user_name') ?? 'Jane Doe';
    
    // Load user profile
    final profileJson = prefs.getString('user_profile');
    if (profileJson != null) {
      try {
        _userProfile = Map<String, dynamic>.from(json.decode(profileJson));
      } catch (e) {
        print('Error loading user profile: $e');
        // Keep default profile if loading fails
      }
    }
    
    // Load custom avatar
    _customAvatar = prefs.getString('custom_avatar');

    // Load role
    final savedRole = prefs.getString('user_role');
    if (savedRole != null && savedRole.isNotEmpty) {
      _userProfile['role'] = savedRole;
    }
  }

  // Save user data to SharedPreferences
  static Future<void> _saveUserData() async {
    final prefs = await _prefs;
    
    // Save user name
    await prefs.setString('user_name', _currentUserName);
    
    // Save user profile as JSON
    await prefs.setString('user_profile', json.encode(_userProfile));
    
    // Save custom avatar
    if (_customAvatar != null) {
      await prefs.setString('custom_avatar', _customAvatar!);
    } else {
      await prefs.remove('custom_avatar');
    }

    // Save role
    if (_userProfile.containsKey('role')) {
      final role = _userProfile['role']?.toString() ?? '';
      if (role.isNotEmpty) {
        await prefs.setString('user_role', role);
      } else {
        await prefs.remove('user_role');
      }
    }
  }

  // Get current user name
  static String getCurrentUserName() {
    return _currentUserName;
  }

  // Get user initial
  static String getUserInitial() {
    if (_currentUserName.isNotEmpty) {
      return _currentUserName[0].toUpperCase();
    }
    return 'U'; // Default initial if no name
  }

  // Get complete user profile
  static Map<String, dynamic> getUserProfile() {
    return Map.from(_userProfile);
  }

  // Update user name
  static Future<void> updateUserName(String newName) async {
    _currentUserName = newName;
    _userProfile['name'] = newName;
    await _saveUserData();
  }

  // Update complete user profile
  static Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    _userProfile.addAll(profileData);
    if (profileData.containsKey('name')) {
      _currentUserName = profileData['name'];
    }
    await _saveUserData();
  }

  // Update specific profile field
  static Future<void> updateProfileField(String field, dynamic value) async {
    _userProfile[field] = value;
    if (field == 'name') {
      _currentUserName = value.toString();
    }
    await _saveUserData();
  }

  // Set custom avatar (for future implementation)
  static Future<void> setCustomAvatar(String? avatarPath) async {
    _customAvatar = avatarPath;
    await _saveUserData();
  }

  // Set user email (for login integration)
  static Future<void> setUserEmail(String email) async {
    _userProfile['email'] = email;
    await _saveUserData();
  }

  // Get user role
  static String getUserRole() {
    final role = _userProfile['role'];
    if (role == null) return 'patient';
    final roleStr = role.toString().trim();
    return roleStr.isEmpty ? 'patient' : roleStr;
  }

  // Set user role
  static Future<void> setUserRole(String role) async {
    _userProfile['role'] = role;
    await _saveUserData();
  }

  // Update FCM token for current user
  static Future<void> updateFCMTokenForCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await NotificationService.updateFCMTokenForUser(user.uid);
      }
    } catch (e) {
      print('Error updating FCM token for current user: $e');
    }
  }

  // Get user email
  static String getUserEmail() {
    return _userProfile['email'] ?? '';
  }

  // Get custom avatar (for future implementation)
  static String? getCustomAvatar() {
    return _customAvatar;
  }

  // Check if user has custom avatar
  static bool hasCustomAvatar() {
    return _customAvatar != null && _customAvatar!.isNotEmpty;
  }

  // Simple encryption/decryption for credentials (basic obfuscation)
  static String _encrypt(String text) {
    final random = Random(42); // Fixed seed for consistency
    final encrypted = text.split('').map((char) {
      return String.fromCharCode(char.codeUnitAt(0) + random.nextInt(10) + 1);
    }).join('');
    return encrypted;
  }

  static String _decrypt(String encrypted) {
    final random = Random(42); // Same seed for decryption
    final decrypted = encrypted.split('').map((char) {
      return String.fromCharCode(char.codeUnitAt(0) - random.nextInt(10) - 1);
    }).join('');
    return decrypted;
  }

  // Remember me functionality using Firestore
  static Future<void> saveRememberMeCredentials(String email, String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Encrypt credentials before storing
        final encryptedEmail = _encrypt(email);
        final encryptedPassword = _encrypt(password);
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'rememberMe': true,
          'rememberedEmail': encryptedEmail,
          'rememberedPassword': encryptedPassword,
          'rememberMeUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error saving remember me credentials to Firestore: $e');
      // Fallback to SharedPreferences if Firestore fails
      final prefs = await _prefs;
      await prefs.setString('remembered_email', email);
      await prefs.setString('remembered_password', password);
      await prefs.setBool('remember_me', true);
    }
  }

  static Future<void> clearRememberMeCredentials() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'rememberMe': false,
          'rememberedEmail': FieldValue.delete(),
          'rememberedPassword': FieldValue.delete(),
          'rememberMeUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error clearing remember me credentials from Firestore: $e');
      // Fallback to SharedPreferences
      final prefs = await _prefs;
      await prefs.remove('remembered_email');
      await prefs.remove('remembered_password');
      await prefs.setBool('remember_me', false);
    }
  }

  static Future<Map<String, String?>> getRememberedCredentials() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          final rememberMe = data['rememberMe'] ?? false;
          
          if (rememberMe && data['rememberedEmail'] != null && data['rememberedPassword'] != null) {
            // Decrypt credentials
            final decryptedEmail = _decrypt(data['rememberedEmail']);
            final decryptedPassword = _decrypt(data['rememberedPassword']);
            
            return {
              'email': decryptedEmail,
              'password': decryptedPassword,
            };
          }
        }
      }
    } catch (e) {
      print('Error getting remember me credentials from Firestore: $e');
      // Fallback to SharedPreferences
      final prefs = await _prefs;
      final email = prefs.getString('remembered_email');
      final password = prefs.getString('remembered_password');
      return {'email': email, 'password': password};
    }
    
    return {'email': null, 'password': null};
  }

  static Future<bool> isRememberMeEnabled() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          return data['rememberMe'] ?? false;
        }
      }
    } catch (e) {
      print('Error checking remember me status from Firestore: $e');
      // Fallback to SharedPreferences
      final prefs = await _prefs;
      return prefs.getBool('remember_me') ?? false;
    }
    
    return false;
  }
}
