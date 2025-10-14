// Test file to demonstrate role-based authentication
// This file shows how the role-based authentication system works

import 'package:demo_app/services/user_service.dart';

class RoleAuthTest {
  static void testRoleDetermination() {
    print('=== Role-Based Authentication Test ===\n');
    
    // Test different email patterns
    final testEmails = [
      'patient@example.com',
      'doctor@example.com', 
      'dr.smith@example.com',
      'admin@example.com',
      'administrator@example.com',
      'user@example.com',
    ];
    
    print('Testing role determination based on email patterns:');
    for (final email in testEmails) {
      final role = UserService.determineUserRole(email);
      print('Email: $email -> Role: $role');
    }
    
    print('\n=== Dashboard Route Test ===\n');
    
    // Test dashboard routes for different roles
    final roles = ['patient', 'doctor', 'admin'];
    for (final role in roles) {
      // Simulate setting role
      UserService.setUserRole(role);
      final route = UserService.getDashboardRoute();
      print('Role: $role -> Dashboard Route: $route');
    }
    
    print('\n=== Role Check Test ===\n');
    
    // Test role checking methods
    UserService.setUserRole('admin');
    print('Current role: ${UserService.getUserRole()}');
    print('Is Admin: ${UserService.isAdmin()}');
    print('Is Doctor: ${UserService.isDoctor()}');
    print('Is Patient: ${UserService.isPatient()}');
    
    UserService.setUserRole('doctor');
    print('\nCurrent role: ${UserService.getUserRole()}');
    print('Is Admin: ${UserService.isAdmin()}');
    print('Is Doctor: ${UserService.isDoctor()}');
    print('Is Patient: ${UserService.isPatient()}');
    
    UserService.setUserRole('patient');
    print('\nCurrent role: ${UserService.getUserRole()}');
    print('Is Admin: ${UserService.isAdmin()}');
    print('Is Doctor: ${UserService.isDoctor()}');
    print('Is Patient: ${UserService.isPatient()}');
  }
}

// Usage example:
// To test the role-based authentication system, call:
// RoleAuthTest.testRoleDetermination();
