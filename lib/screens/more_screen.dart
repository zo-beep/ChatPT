import 'package:demo_app/main.dart';
import 'package:demo_app/screens/main_screen.dart';
import 'package:demo_app/screens/patient_dashboard_screen.dart';
import 'package:demo_app/screens/about_screen.dart';
import 'package:demo_app/screens/terms_conditions_screen.dart';
import 'package:demo_app/screens/help_support_screen.dart';
import 'package:demo_app/screens/reminders_screen.dart';
import 'package:flutter/material.dart';
import 'package:demo_app/screens/doctor_dashboard_screen.dart';
import 'package:demo_app/screens/admin_dashboard_screen.dart';
import 'package:demo_app/services/user_service.dart';

// MORE SCREEN
class MoreScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const MoreScreen({super.key, required this.themeProvider});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {

  @override
  Widget build(BuildContext context) {
    final themeProvider = widget.themeProvider;
    final isDarkTheme = themeProvider.isDarkTheme;
    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: themeProvider.primaryColor,
          ),
          onPressed: () {
            Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen(themeProvider: themeProvider,)),
            );
          },
        ),
        title: Text(
          'Back',
          style: TextStyle(
            color: themeProvider.primaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text(
                      'ChatPT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Menu Items Grouped in a Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      'Profile',
                      Icons.arrow_forward_ios,
                      onTap: () {
                        // Navigate based on user role
                        final userRole = UserService.getUserRole();
                        Widget dashboardScreen;
                        if (userRole == 'doctor') {
                          dashboardScreen = DoctorDashboardScreen(themeProvider: themeProvider);
                        } else if (userRole == 'admin') {
                          dashboardScreen = AdminDashboardScreen(themeProvider: themeProvider);
                        } else {
                          dashboardScreen = PatientDashboardScreen(themeProvider: themeProvider);
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => dashboardScreen,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      'Reminders',
                      Icons.arrow_forward_ios,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RemindersScreen(themeProvider: themeProvider),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      'About',
                      Icons.arrow_forward_ios,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutScreen(themeProvider: themeProvider),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      'Term & Conditions',
                      Icons.arrow_forward_ios,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TermsConditionsScreen(themeProvider: themeProvider),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      'Help & Support',
                      Icons.arrow_forward_ios,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HelpSupportScreen(themeProvider: themeProvider),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // Theme Toggle as a card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: themeProvider.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Theme',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: themeProvider.textColor,
                            ),
                          ),
                          Switch(
                            value: isDarkTheme,
                            onChanged: (value) {
                              themeProvider.toggleTheme();
                            },
                            activeThumbColor: themeProvider.primaryColor,
                            activeTrackColor: themeProvider.primaryColor.withOpacity(0.5),
                            inactiveThumbColor: themeProvider.primaryColor,
                            inactiveTrackColor: themeProvider.primaryColor.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Logout',
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
    );
  }

  Widget _buildMenuItem(String title, IconData icon, {VoidCallback? onTap}) {
    final themeProvider = widget.themeProvider;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: themeProvider.secondaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: themeProvider.textColor,
              ),
            ),
            Icon(
              icon,
              size: 18,
              color: themeProvider.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}