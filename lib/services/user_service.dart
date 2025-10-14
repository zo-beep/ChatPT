import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
    'diagnosis': 'Knee Pain',
    'medications': 'Glucosamine',
    'assignedDoctor': 'Dr. John Doe',
    'therapyStartDate': 'December 4, 2025',
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
}
